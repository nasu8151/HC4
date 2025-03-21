use std::env;
use std::fs::File;
use std::io::{ BufReader, BufRead, Write, BufWriter };
extern crate regex;
use regex::Regex;

extern crate getopts;
use getopts::Options;

extern crate colored; // not needed in Rust 2018+
use colored::Colorize;


//NOTE:This table DON'T INCLUDE NP INSTRUCTION
const _INSTRUCTION_STRINGS: [&str;16] = [
    "SC", "XR", "LD", "",
    "SC", "OR", "LD", "",
    "SU", "AN", "LD", "JP",
    "AD", "SA", "", "",
];

const COMMENT_STR: &str = r"(?:;.*)?$";

//命令文と、代に引数をキャプチャする正規表現の文字列の配列
const INSTRUCTION_MATRIX_DATA: [&str; 16] = {
    const JP_DATA: &str = r"^(jp|np)(?:\s(c|nc|z|nz))?(?:\s\[abc\])?";
    [
        r"^(sc)(?:\s\[ab\])?", r"^(xr)\sr(\d+)", r"^(ld)(?:\s\[ab\])?", r"^",
        r"^(sc)\sr(\d+)", r"^(or)\sr(\d+)", r"^(ld)\sr(\d+)", r"^",
        r"^(su)\sr(\d+)", r"^(an)\sr(\d+)", r"^(ld)\s#(\d+)", JP_DATA,
        r"^(ad)\sr(\d+)", r"^(sa)\sr(\d+)", r"^", r"^",
    ]
};

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

fn print_usage(program: &str, opts: Options) {
    let brief = format!("Usage: {} FILE [options]", program);
    print!("{}", opts.usage(&brief));
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

    //temporary data
    let mut bin_buf: Vec<u8> = Vec::new();

    /*アセンブラそのものの構文定義。
    * ここではアルファベットによる命令と二つの引数を半角スペースで区切ることを定義。
    */
    let _line_rgx: Regex = Regex::new(r"^([a-zA-Z]+)(?:\s(.+))(?:\s(.+))").expect("REASON");
    let _instruction_table: [Regex;16] = get_instruction_table().map(|i| Regex::new(&(i + r"\s*" + COMMENT_STR)).unwrap());
    let white_line = Regex::new(r"^\s*$").unwrap();


    let source_file_path = &args[1];
    let mut num_of_error = 0;
    let mut line_index = 0;
    for line in BufReader::new(File::open(source_file_path)?).lines() {
        let l = String::from(line?).to_lowercase();
        if white_line.is_match(&l) { continue; }
        let mut is_line_error = true;
        for i in 0.._instruction_table.len() {
            match _instruction_table[i].captures(&l) {
                Some(caps) => { //行を解釈できた
                    is_line_error = false;
                    let opc: u8 = i.try_into().unwrap();
                    let opr: u8 = if i == 0b1110 {
                        if &caps[1] == "np" { 0b0001 }
                        else {
                            match caps.get(2) {
                                Some(value) => match value.as_str() {
                                    "c" => 0b0010,
                                    "nc" => 0b0011,
                                    "z" => 0b0100,
                                    "nz" => 0b0101,
                                    &_ => 0b0000,
                                }
                                None => 0b0000,
                            }
                        }
                    } else {
                        match caps.get(2) {
                            Some(value) => value.as_str().parse().unwrap(),
                            None => 0
                        }
                    };
                    //バッファに追加
                    bin_buf.push(opc * 0b10000 + opr);
                },
                None => { //行を解釈できなかった
                }
            }
        }
        if is_line_error {
            num_of_error += 1;
            println!("error line;{}",line_index);
        }
        line_index += 1;
    }

    if num_of_error > 0 {
        println!("{}",(source_file_path.to_owned() + " has " + &num_of_error.to_string() + " errors").red());
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
