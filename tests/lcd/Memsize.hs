import System.IO

main = readFile "inst_mem.hex" >>= putStrLn . show . (`sub` 1) . length . words where sub a b = a - b
