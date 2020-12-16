module UtilsSpec
  ( spec,
  )
where

import qualified Test.Hspec as T
import qualified Utils as U

spec :: T.Spec
spec = T.it "should be equal" (U.equal (1 :: Int) 1)
