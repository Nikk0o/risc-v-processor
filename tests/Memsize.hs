import System.IO

main =
  putStrLn "Size of memory:" >> readFile "mem.hex" >>= putStrLn . (++" bytes") . show . length . (filter (not . (any (=='@')))) . words
