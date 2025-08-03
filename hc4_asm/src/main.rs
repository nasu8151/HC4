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
    const JP_DATA: &str = r"(jp|np)(?:\s(\w+))?(?:\s\[abc\])?";
    const JL_LP_DATA: &str = r"(jl|lp)(?:\s(\w+))?(?:\s\[abc\])?";
        [
        r"(sc)(?:\s\[ab\])?", r"(xr)\sr(\w+)", r"(ld)(?:\s\[ab\])?" , r"(ls)\s#(\w+)", // ← 0xC: LS追加
        r"(sc)\sr(\w+)"     , r"(or)\sr(\w+)", r"(ld)\sr(\w+)"      , r"",
        r"(su)\sr(\w+)"     , r"(an)\sr(\w+)", r"(ld)\s#(\w+)"      , JP_DATA,          // ← 0xE: JP
        r"(ad)\sr(\w+)"     , r"(sa)\sr(\w+)", r""                  , JL_LP_DATA        // ← 0xF: JL/LP
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

/// Write binary data to a file in Intel HEX format
fn write_intel_hex(bin: &[u8], writer: &mut dyn Write) -> std::io::Result<()> {
    let mut addr = 0u16;
    while (addr as usize) < bin.len() {
        let remaining = bin.len() - addr as usize;
        let count = if remaining >= 16 { 16 } else { remaining };
        let chunk = &bin[addr as usize..addr as usize + count];

        let record = make_intel_hex_record(addr, chunk);
        writeln!(writer, "{}", record)?;

        addr += count as u16;
    }
    // EOF record
    writeln!(writer, ":00000001FF")?;
    Ok(())
}

fn make_intel_hex_record(addr: u16, data: &[u8]) -> String {
    let byte_count = data.len() as u8;
    let record_type = 0x00;
    let high = (addr >> 8) as u8;
    let low = (addr & 0xFF) as u8;

    let mut sum: u8 = byte_count.wrapping_add(high)
                                .wrapping_add(low)
                                .wrapping_add(record_type);

    let mut data_str = String::new();
    for &b in data {
        sum = sum.wrapping_add(b);
        data_str.push_str(&format!("{:02X}", b));
    }

    let checksum = (!sum).wrapping_add(1);

    format!(
        ":{:02X}{:04X}{:02X}{}{:02X}",
        byte_count,
        addr,
        record_type,
        data_str,
        checksum
    )
}

/// Write assembly list file
fn write_list_file(assembly_lines: &[AssemblyLine], labels: &[Label], writer: &mut dyn Write) -> std::io::Result<()> {
    writeln!(writer, "HC4 Assembly List File")?;
    writeln!(writer, "======================")?;
    writeln!(writer)?;
    
    // ラベルテーブルを出力
    if !labels.is_empty() {
        writeln!(writer, "Label Table:")?;
        writeln!(writer, "-----------")?;
        for label in labels {
            writeln!(writer, "{:<16} = {:04X} (Line {:3})", label.name, label.address, label.line_number)?;
        }
        writeln!(writer)?;
    }
    
    writeln!(writer, "Address  Machine Code  Line#  Source")?;
    writeln!(writer, "-------  ------------  -----  ------")?;
    
    for line in assembly_lines {
        let addr_str = if line.machine_code.is_some() || line.label.is_some() {
            format!("{:04X}", line.address)
        } else {
            "    ".to_string()
        };
        
        let machine_code_str = match line.machine_code {
            Some(code) => format!("{:02X}", code),
            None => "  ".to_string(),
        };
        
        let error_mark = if line.error != AsmErrors::NotError { " *ERROR*" } else { "" };
        
        // ラベルがある場合は特別な表示
        let label_mark = if line.label.is_some() { "<LABEL>" } else { "" };
        
        writeln!(
            writer,
            "{}     {}         {:5}  {}{}{}",
            addr_str,
            machine_code_str,
            line.line_number,
            line.source_line.trim(),
            error_mark,
            if !label_mark.is_empty() { format!(" {}", label_mark) } else { String::new() }
        )?;
    }
    
    writeln!(writer)?;
    writeln!(writer, "End of assembly list")?;
    Ok(())
}

/// Print usage information
/// for the program
/// # Arguments
/// * `program` - The name of the program
/// * `opts` - The options for the program
fn print_usage(program: &str, opts: Options) {
    let brief = format!("Usage: {} FILE [options]", program);
    print!("{}", opts.usage(&brief));
}

#[derive(Debug,PartialEq,Clone)]
enum AsmErrors {
    NotError,
    NonexistentInstruction,
    UnexpectedSyntax,
    NonValidLiter,
    NonFlag,
}

#[derive(Debug, Clone)]
struct AssemblyLine {
    line_number: usize,
    address: usize,
    machine_code: Option<u8>,
    source_line: String,
    error: AsmErrors,
    label: Option<String>,
}

#[derive(Debug, Clone)]
struct Label {
    name: String,
    address: usize,
    line_number: usize,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    let program = args[0].clone();

    let mut opts = Options::new();
    opts.optopt("o", "", "set output file name", "NAME");
    opts.optopt("f", "format", "output format: hex or ihex", "FORMAT");
    opts.optopt("l", "list", "generate assembly list file", "LIST_FILE");
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
    let mut assembly_lines: Vec<AssemblyLine> = Vec::new();
    let mut labels: Vec<Label> = Vec::new();

    /*アセンブラそのものの構文定義。
    * ここではアルファベットによる命令と二つの引数を半角スペースで区切ることを定義。
    */
    let line_rgx: Regex = Regex::new(r"^\s*([a-zA-Z]+)(?:\s[r#]?(\w+))?").expect("REASON");
    let _instruction_table: [Regex;16] = get_instruction_table().map(|i| {
        if i.is_empty() {
            Regex::new(r"$a").unwrap() // 決してマッチしない正規表現
        } else {
            Regex::new(&(String::from(r"^\s*") + &i + r"\s*" + COMMENT_STR)).unwrap()
        }
    });
    let white_line = Regex::new(r"^\s*$").unwrap();
    let label_rgx = Regex::new(r"^\s*([a-zA-Z_][a-zA-Z0-9_]*):").unwrap();

    let source_file_path = &args[1];
    let mut num_of_error = 0;
    let mut line_index = 0;

    let mut line_error;
    let mut is_line_interpreted;
    let mut current_address = 0;
    for line in BufReader::new(File::open(source_file_path)?).lines() {
        line_index += 1;
        let original_line = line?;
        let l = original_line.to_lowercase(); //ファイルを読めたらすぐに小文字に変換
        
        // 空行の場合は記録のみして次へ
        if white_line.is_match(&l) { 
            assembly_lines.push(AssemblyLine {
                line_number: line_index,
                address: current_address,
                machine_code: None,
                source_line: original_line,
                error: AsmErrors::NotError,
                label: None,
            });
            continue; 
        }

        line_error = AsmErrors::NotError; // 一度、構文エラーとして設定
        is_line_interpreted = false; //この行が構文解釈に引っかかったことがあるか。
        let mut generated_machine_code: Option<u8> = None;
        let mut current_line_label: Option<String> = None;

        // ラベルを検出
        if let Some(caps) = label_rgx.captures(&l) {
            let label_name = caps[1].to_string();
            labels.push(Label {
                name: label_name.clone(),
                address: current_address,
                line_number: line_index,
            });
            current_line_label = Some(label_name);
        }

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
                    let machine_code = opc * 0b10000 + opr;
                    bin_buf.push(machine_code);
                    generated_machine_code = Some(machine_code);
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
        
        // 各行の情報を記録
        assembly_lines.push(AssemblyLine {
            line_number: line_index,
            address: current_address,
            machine_code: generated_machine_code,
            source_line: original_line,
            error: line_error.clone(),
            label: current_line_label,
        });
        
        // アドレスを更新（マシンコードが生成された場合のみ）
        if generated_machine_code.is_some() {
            current_address += 1;
        }
    }

    if num_of_error > 0 {
        println!("Assembly failed : {}", (source_file_path.to_owned() + " has " + &num_of_error.to_string() + " error(s)").red());
        println!("I have no idea.");
        
        // エラーがあってもリストファイルは生成する
        if let Some(list_file_path) = matches.opt_str("l") {
            println!("generating list file with errors...");
            let mut list_writer = BufWriter::new(File::create(list_file_path)?);
            write_list_file(&assembly_lines, &labels, &mut list_writer)?;
            list_writer.flush()?;
            println!("{}","list file generated with errors!".yellow().bold());
        }
    } else {
        let format = matches.opt_str("f").unwrap_or("hex".to_string());
        if format != "hex" && format != "ihex" {
            println!("Unsupported format '{}'. Use 'hex' or 'ihex'", format);
            return Ok(());
        }

        println!("writing...");
        //File writer
        let mut writer = BufWriter::new(File::create(output)?);
        if format == "ihex" {
            write_intel_hex(&bin_buf, &mut writer)?;
        } else {
            for byte in bin_buf {
                writeln!(writer, "{:02X}", byte)?;
            }
        }
        writer.flush()?;
        println!("{}","success!".cyan().bold());
        println!("exit writing hex file");
        
        // リストファイルの生成
        if let Some(list_file_path) = matches.opt_str("l") {
            println!("generating list file...");
            let mut list_writer = BufWriter::new(File::create(list_file_path)?);
            write_list_file(&assembly_lines, &labels, &mut list_writer)?;
            list_writer.flush()?;
            println!("{}","list file generated!".cyan().bold());
        }
    }



    Ok(())
}
