use std::env;
use std::fs::File;
use std::io::{ BufReader, BufRead };

use regex::Regex;


//NOTE:This table DON'T INCLUDE NP INSTRUCTION
const _INSTRUCTION_STRINGS: [&str;16] = [
    "SC", "XR", "LD", "",
    "SC", "OR", "LD", "",
    "SU", "AN", "LD", "JP",
    "AD", "SA", "", "",
];

//命令文と、代に引数をキャプチャする正規表現の文字列の配列
const INSTRUCTION_MATRIX_DATA: [&str; 16] = [
    r"^SC(?:\s\[AB\])?", r"^XR\sr(\d+)", r"^LD(?:\s\[AB\])?", "",
    r"^SC\sr(\d+)", r"^OR\sr(\d+)", r"^LD\sr(\d+)", "",
    r"^SU\sr(\d+)", r"^AN\sr(\d+)", r"^LD\s#(\d+)", r"^(?:JP(?:\s((?:C|NC|Z|NZ)))?(?:\s\[ABC\])?)|NP",
    r"^AD\sr(\d+)", r"^SA\sr(\d+)", "", "",
];

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    dbg!(&args);

    let source_file_path = &args[1];
    for line in BufReader::new(File::open(source_file_path)?).lines() {
        let l = line?;
        println!("{}", l);
    }

    Ok(())
}
