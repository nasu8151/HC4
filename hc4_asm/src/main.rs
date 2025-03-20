use std::env;
use std::fs::File;
use std::io::{ BufReader, BufRead };

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
