data Type = R | I | S | J | U | B

splitBy :: Eq  a => [a] -> a -> [[a]]
splitBy l k =
  split' l k []
  where
    split' [] _ a = [a]
    split' (x:xs) k a
      | x == k = a : split' xs k []
      | otherwise = split' xs k (a ++ [x])

checkRegister :: String -> Either String Integer
checkRegister r =
  case r of
    "zero" -> Right 0
    "ra" -> Right 1
    "sp" -> Right 2
    "gp" -> Right 3
    "tp" -> Right 4
    "fp" -> Right 8
    ('a':xs) -> if read xs >= 0 && read xs < 8 then
                  Right $ read xs
                else
                  Left $ "Invalid register: " ++ ('a':xs)
    ('t':xs) -> if read xs >= 0 && read xs < 7 then
                  Right $ read xs
                else
                  Left $ "Invalid register: " ++ ('t':xs)
    ('s':xs) -> if read xs >= 0 && read xs < 12 then
                  Right $ read xs
                else
                  Left $ "Invalid register: " ++ ('s':xs)
    k -> Left $ "Invalid register: " ++ k

checkInstruction :: String -> Either String (Type, Integer, Integer, Integer)
checkInstruction instruct
  | instruct == "add" = Right (R, 0o0110011, 0o0, 0x00)
  | instruct == "sub" = Right (R, 0o0110011, 0o0, 0x20)
  | instruct == "xor" = Right (R, 0o0110011, 0x4, 0x00)
  | instruct == "or"  = Right (R, 0o0110011, 0x6, 0x00)
  | instruct == "and" = Right (R, 0o0110011, 0x7, 0x00)
  | instruct == "sll" = Right (R, 0o0110011, 0x1, 0x00)
  | instruct == "srl" = Right (R, 0o0110011, 0x5, 0x00)
  | instruct == "sra" = Right (R, 0o0110011, 0x5, 0x20)
  | instruct == "slt" = Right (R, 0o0110011, 0x2, 0x00)
  | instruct == "addi" = Right (I, 0o0010011, 0x0, 0x0)
