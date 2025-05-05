use std::env;
use std::fs::File;
use std::io::{ BufReader, BufRead, Write, BufWriter };
use std::num::ParseIntError;
extern crate regex;
use regex::Regex;

extern crate getopts;
use getopts::Options;

extern crate colored; // not needed in Rust 2018+
use colored::Colorize;


//NOTE:This table DON'T INCLUDE NP INSTRUCTION
const INSTRUCTION_STRINGS: [&str; 13] = ["sc", "xr", "ld", "or", "su", "an", "jp", "ad", "sa", "np", "ls", "lp", "jl"];

const COMMENT_STR: &str = r"(?:;.*)?$";

//命令文と、代に引数をキャプチャする正規表現の文字列の配列
const INSTRUCTION_MATRIX_DATA: [&str; 16] = {
    const JP_DATA: &str = r"^(jp|np)(?:\s(\w+))?(?:\s\[abc\])?";
    const JL_LP_DATA: &str = r"^(jl|lp)(?:\s(\w+))?(?:\s\[abc\])?";
        [
        r"^(sc)(?:\s\[ab\])?", r"^(xr)\sr(\w+)", r"^(ld)(?:\s\[ab\])?" , r"^(ls)\s#(\w+)", // ← 0xC: LS追加
        r"^(sc)\sr(\w+)"     , r"^(or)\sr(\w+)", r"^(ld)\sr(\w+)"      , r"^",
        r"^(su)\sr(\w+)"     , r"^(an)\sr(\w+)", r"^(ld)\s#(\w+)"      , JP_DATA,          // ← 0xE: JP
        r"^(ad)\sr(\w+)"     , r"^(sa)\sr(\w+)", r"^"                  , JL_LP_DATA        // ← 0xF: JL/LP
    ]
};

const _REGISTER_INSTRUCTION: [u8; 8] = [1,2,3,4,5,6,7,9,];
const _IMMEDIATE_INSTRUCTION: [u8; 2] = [10,12,];

const OPCODE_JP_NP: usize = 0xE;
const OPCODE_JL_LP: usize = 0xF;

const INSTRUCTION_MATRIX_DATA_X: usize = 4;
const INSTRUCTION_MATRIX_DATA_Y: usize = 4;

fn get_instruction_table() -> [String; 16] {
    let col_num = INSTRUCTION_MATRIX_DATA_X;
    let row_num = INSTRUCTION_MATRIX_DATA_Y;

    let mut result: [String; 16] = Default::default();
    for x in 0..col_num {
        for y in 0..row_num {
            result[col_num * x + y] = INSTRUCTION_MATRIX_DATA[row_num * y + x].to_string();
        }
    }
    result
}

/// Parse string into u8. Supports:
/// - "0xA" (hex)
/// - "0b1010" (binary)
/// - "10" (decimal)
fn parse_to_u8(input: &str) -> Result<u8, ParseIntError> {
    if input.starts_with("0x") {
        u8::from_str_radix(&input[2..], 16)
    } else if input.starts_with("0b") {
        u8::from_str_radix(&input[2..], 2)
    } else {
        input.parse::<u8>()
    }
}

fn print_usage(program: &str, opts: Options) {
    let brief = format!("Usage: {} FILE [options]", program);
    print!("{}", opts.usage(&brief));
}

#[derive(Debug,PartialEq)]
enum AsmErrors {
    NotError,
    NonexistentInstruction,
    UnexpectedSyntax,
    NonValidLiter,
    NonFlag,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    let program = args[0].clone();

    let mut opts = Options::new();
    opts.optopt("o", "", "set output file name", "NAME");
    opts.optflag("h", "help", "print this help menu");

    let matches = match opts.parse(&args[2..]) {
        Ok(m) => { m },
        Err(f)  => { panic!("{}",f.to_string())}
    };
    if matches.opt_present("h") {
        print_usage(&program, opts);
        return Ok(());
    }
    let output = match matches.opt_str("o") {
        Some(p) => p,
        None => {
            println!("please set option -o output file path");
            return Ok(());
        },
    };

    fn parse_flag_to_opr(flag: Option<regex::Match>) -> Result<u8, AsmErrors> { //フラグを数値に変換する関数
        match flag {
            Some(f) => match f.as_str() {
                "c" => Ok(0b0010),  //キャリー
                "nc" => Ok(0b0011), //ノンキャリー
                "z" => Ok(0b0100),  //ゼロ
                "nz" => Ok(0b0101), //ノンゼロ
                "t" => Ok(0b0110),  //トリガー
                "nt" => Ok(0b0111), //ノントリガー
                _ => Err(AsmErrors::NonFlag),
            },
            None => Ok(0b0000),
        }
    }    

    //temporary data
    let mut bin_buf: Vec<u8> = Vec::new();

    /*アセンブラそのものの構文定義。
    * ここではアルファベットによる命令と二つの引数を半角スペースで区切ることを定義。
    */
    let line_rgx: Regex = Regex::new(r"^([a-zA-Z]+)(?:\s[r#]?(\w+))?").expect("REASON");
    let _instruction_table: [Regex;16] = get_instruction_table().map(|i| Regex::new(&(i + r"\s*" + COMMENT_STR)).unwrap());
    let white_line = Regex::new(r"^\s*$").unwrap();

    let source_file_path = &args[1];
    let mut num_of_error = 0;
    let mut line_index = 0;

    let mut line_error;
    let mut is_line_interpreted;
    for line in BufReader::new(File::open(source_file_path)?).lines() {
        line_index += 1;
        let l = String::from(line?).to_lowercase(); //ファイルを読めたらすぐに小文字に変換
        if white_line.is_match(&l) { continue; }

        line_error = AsmErrors::NotError; // 一度、構文エラーとして設定
        is_line_interpreted = false; //この行が構文解釈に引っかかったことがあるか。

        for i in 0.._instruction_table.len() {
            match _instruction_table[i].captures(&l) {
                Some(caps) => { //行を解釈できた
                    is_line_interpreted = true;
                    line_error = AsmErrors::NotError; //一度 NotError にし、その後の解釈でエラーがあれば、true とする。
                    let opc: u8 = i.try_into().unwrap();
                    let opr: u8 = if i == OPCODE_JP_NP { // JP または NP の場合
                        if &caps[1] == "np" { 0b0001 } //NP 構文のみ、JP命令記述ではないがJPと同じ命令 opc の bit のため例外処理を与える
                        else {
                            match parse_flag_to_opr(caps.get(2)) {
                                Ok(v) => v,
                                Err(e) => {
                                    line_error = e;
                                    0b0000
                                }
                            }
                        }
                    } else if i == OPCODE_JL_LP { //LP の場合
                        if &caps[1] == "lp" { 0b0001 } //LP 構文のみ、JP命令記述ではないがJLと同じ命令 opc の bit のため例外処理を与える
                        else {
                            match parse_flag_to_opr(caps.get(2)) {
                                Ok(v) => v,
                                Err(e) => {
                                    line_error = e;
                                    0b0000
                                }
                            }
                        }
                    } else { //JP ではなく、NPではない命令記述
                        match caps.get(2) {
                            Some(value) => {
                                match parse_to_u8(value.as_str()) {
                                    Ok(value) => { //文字列を数字として解釈できた場合
                                        if value < 16 { value }
                                        else {
                                            line_error = AsmErrors::NonValidLiter; //エラー。解釈できないリテラル。
                                            0b0000
                                        }
                                    },
                                    Err(_e) => { //文字列を数字として解釈できなかった場合（エラー）
                                        line_error = AsmErrors::NonValidLiter; //エラー。解釈できないリテラル。
                                        0b0000
                                    },
                                }
                            },
                            None => 0b0000
                        }
                    };
                    //バッファに追加
                    bin_buf.push(opc * 0b10000 + opr);
                },
                None => {} //この正規表現では解釈されなかった
            }
        }

        if is_line_interpreted {
            match line_rgx.captures(&l) {
                Some(caps) => {
                    if !INSTRUCTION_STRINGS.contains(&&caps[1]) {
                        println!("{}",&caps[1]);
                        line_error = AsmErrors::NonexistentInstruction;
                    }
                },
                None => line_error = AsmErrors::UnexpectedSyntax,
            }
        }
        if line_error != AsmErrors::NotError {
            num_of_error += 1;
            let num_of_line_decimal_digits = {
                let mut copy_index = line_index + 1;
                let mut count = 1;
                while 10 <= copy_index { 
                    count += 1;
                    copy_index /= 10;
                }
                count
            };
            let space = " ".repeat(num_of_line_decimal_digits + 1);
            let border_code_space = "     ";
            println!("{error}: {mes}\n   --> {source_path}:{line}\n{space}|\n{line} |{space2}{code}\n{space}|\n{space}|\n",
                error="error".red(),
                mes=match line_error {
                    AsmErrors::NotError => "if you see this message, please contact the developer",
                    AsmErrors::NonexistentInstruction => "nonexistent instruction",
                    AsmErrors::UnexpectedSyntax => "unexpected syntax",
                    AsmErrors::NonValidLiter => "nonexistent valid literal",
                    AsmErrors::NonFlag => "nonexistent flag",
                },
                source_path=source_file_path,
                line=line_index + 1,
                space=space,
                space2=border_code_space,
                code=l,
            );
        }
    }

    if num_of_error > 0 {
        println!("Assembly failed : {}", (source_file_path.to_owned() + " has " + &num_of_error.to_string() + " error(s)").red());
    } else {
        println!("writing...");
        //File writer
        let mut writer = BufWriter::new(File::create(output)?);

        for byte in bin_buf {
            writer.write_all(format!("{:02X}",byte).as_bytes())?;
            writer.write_all(b"\n")?;
        }
        writer.flush()?;
        println!("{}","success!".cyan().bold());
        println!("exit writing hex file");
    }



    Ok(())
}
