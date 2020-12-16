module Main
  ( main,
  )
where

import qualified Utils as U

main :: IO ()
main = if U.equal True True then putStrLn "Hello World" else putStrLn "Bye"
