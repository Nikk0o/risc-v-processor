import System.IO

main = readFile "inst_mem.hex" >>= putStrLn . show . (\l -> l - 1) . length . words
