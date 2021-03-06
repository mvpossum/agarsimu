{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -funbox-strict-fields #-}
-- |
-- Module:     AgarSimu.PublicEntities
-- Copyright:  (c) 2015 Martin Villagra
-- License:    BSD3
-- Maintainer: Martin Villagra <mvillagra0@gmail.com>

module AgarSimu.PublicEntities
    ( Vector
    
      -- * World
    , WorldConsts(..)
    , worlSize, worlWindowSize, worlFullScreen

      -- * Bola
    , Bola(..)
    , bolColor, bolPos, bolMass
    , bolRadio
    , massToRadio
    , distBolas
    , eats

      -- * Colors
    , rgb
    , randomColor
    , getRgb

      -- * Base Types
    , Time
    , Environment
    , RandomWire
    , AI
    )
    where

import Data.Maybe
import Data.Word (Word8, Word32)
import Control.Monad.Random
import Control.Lens hiding (at, perform, wrapped)
import Data.AffineSpace (distance)
import qualified Graphics.UI.SDL as SDL (Pixel(..))
import Control.Wire hiding ((.))
import AgarSimu.Utils

type Vector = (Double, Double)

--------------------------------------------------------------------------------
data WorldConsts = WorldConsts { _worlSize :: !Vector
                               , _worlWindowSize :: !(Int, Int)
                               , _worlFullScreen :: !Bool
                               } deriving Show
$(makeLenses ''WorldConsts)

--------------------------------------------------------------------------------
data Bola = Bola { _bolColor :: !SDL.Pixel
                 , _bolPos :: !Vector
                 , _bolMass :: !Double
                 } deriving Show
$(makeLenses ''Bola)

bolRadio :: Bola -> Double
bolRadio = massToRadio.(view bolMass)

massToRadio :: Double -> Double
massToRadio = sqrt.(/pi)

distBolas :: Bola -> Bola -> Double
distBolas p q = uncurry distance $ view (bolPos `alongside` bolPos) (p, q)


eats :: Bola -> Bola -> Bool
a `eats` b = view bolMass a / view bolMass b > 1.1 

--------------------------------------------------------------------------------
rgb :: Word8 -> Word8 -> Word8 -> SDL.Pixel
rgb r g b = let fi = fromIntegral
            in SDL.Pixel (fi r *2^24 + fi g*2^16 + fi b*2^8 + 0xff)

randomColor :: MonadRandom m => m SDL.Pixel
randomColor = getRandomR (0, length colors - 1) >>= return.(colors !!)
    where colors = map (SDL.Pixel.(+0xff).(2^8*))
            [ 0x07ffb0, 0x07ffb0, 0xe407ff, 0x9cff07, 0x5a07ff, 0x11ff07
            , 0xff9307, 0xfeff07, 0xff071d, 0x07ffea, 0x17ff07, 0x8807ff
            , 0xffbc07, 0xffd307, 0x7607ff, 0xd907ff, 0x1a07ff, 0x07a2ff
            , 0x2507ff, 0x07ff5a]

getRgb :: SDL.Pixel -> (Word8, Word8, Word8)
getRgb (SDL.Pixel p) = ( md $ p `div` 2^24
                       , md $ p `div` 2^16
                       , md $ p `div` 2^8)
    where md b = fromIntegral (b `mod` 2^8)

--------------------------------------------------------------------------------
type Environment = (Vector, Bola, [Bola])
type Time = NominalDiffTime
type RandomWire = Wire (Timed Time ()) () (Rand StdGen)
type AI = RandomWire Environment Vector
