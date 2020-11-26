{-|
Module      : Utils
Description : Utility functions
Copyright   : (c) Me, 2020
License     : GPL-3
Maintainer  : Pierre Penninckx (ibizapeanut@gmail.com)
Stability   : experimental
Portability : POSIX

Provides some basic utility functions.
-}
module Utils
  ( equal
  )
where

-- | Equality test.
equal :: Eq a => a -> a -> Bool
equal = (==)
