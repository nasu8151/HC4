use std::env;
use std::fs::File;
use std::io::{ BufReader, BufRead };
extern crate regex;
use regex::Regex;


//NOTE:This table DON'T INCLUDE NP INSTRUCTION
const _INSTRUCTION_STRINGS: [&str;16] = [
    "SC", "XR", "LD", "",
    "SC", "OR", "LD", "",
    "SU", "AN", "LD", "JP",
    "AD", "SA", "", "",
];

//命令文と、代に引数をキャプチャする正規表現の文字列の配列
const INSTRUCTION_MATRIX_DATA: [&str; 16] = {
    const JP_DATA: &str = r"^([NP|JP])(?:\s([C|NC|Z|NZ]))?(?:\s\[ABC\])?";
    [
        r"^(SC)(?:\s\[AB\])?", r"^(XR)\sr(\d+)", r"^(LD)(?:\s\[AB\])?", r"^",
        r"^(SC)\sr(\d+)", r"^(OR)\sr(\d+)", r"^(LD)\sr(\d+)", r"^",
        r"^(SU)\sr(\d+)", r"^(AN)\sr(\d+)", r"^(LD)\s#(\d+)", JP_DATA,
        r"^(AD)\sr(\d+)", r"^(SA)\sr(\d+)", r"^", r"^",
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


fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    dbg!(&args);


    /*アセンブラそのものの構文定義。
    * ここではアルファベットによる命令と二つの引数を半角スペースで区切ることを定義。
    */
    let _line_rgx: Regex = Regex::new(r"^([a-zA-Z]+)(?:\s(.+))(?:\s(.+))").expect("REASON");

    
    let _instruction_table: [Regex;16] = get_instruction_table().map(|i| Regex::new(&i).unwrap());
    let white_line = Regex::new(r"^\s*$").unwrap();


    let mut line_index = 0;
    let source_file_path = &args[1];
    for line in BufReader::new(File::open(source_file_path)?).lines() {
        let l = line?;
        let is_correct_syntax = false;
        if white_line.is_match(&l) { continue; }
        for i in 0.._instruction_table.len() {
            match _instruction_table[i].captures(&l) {
                Some(caps) => {
                    is_correct_syntax = true;
                    let opc: u16 = i.try_into().unwrap();
                    let opr: u16 = if i == 0b1110 {
                        if &caps[1] == "NP" { 0b0001 }
                        else {
                            match &caps[2] {
                                None => 0b0000,
                                "C" => 0b0010,
                                "NC" => 0b0011,
                                "Z" => 0b0100,
                                "NZ" => 0b0101,
                            }
                        }
                    } else {
                        match &caps[2] {
                            Some(value) => value.try_into().unwrap(),
                            None => 0
                        }
                    };
                },
                None => {
                    println!("error line:{}",line_index + 1);
                }
            }
        }
        line_index += 1;
    }


    Ok(())
}
