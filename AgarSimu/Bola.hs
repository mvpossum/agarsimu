{-# LANGUAGE Arrows #-}
-- |
-- Module:     AgarSimu.Bola
-- Copyright:  (c) 2015 Martin Villagra
-- License:    BSD3
-- Maintainer: Martin Villagra <mvillagra0@gmail.com>

module AgarSimu.Bola
    ( -- * Wires
      bolaLogic
    , foodGenerator
      
       -- * Environment creator
    , mkEnvs
    )
    where

import Prelude hiding ((.), id, until)
import Data.Maybe
import Control.Lens hiding (at, perform, wrapped)
import Data.VectorSpace ((^+^), (^-^), magnitude, (*^), (^/))
import Data.AffineSpace (distance)
import Control.Wire
import FRP.Netwire
import AgarSimu.PreFab
import AgarSimu.PublicEntities
import AgarSimu.Scene
import AgarSimu.Utils
 
mkEnvs :: [a] -> [[a]]
mkEnvs xs = mkEnvs' [] xs
  where mkEnvs' izq [] = []
        mkEnvs' izq (x:der) = (izq++der):mkEnvs' (x:izq) der

mkBolaVec :: Double -> Bola -> Vector -> Vector
mkBolaVec s b v = s' *^ normalized ^/ r
    where r = (view bolMass b)**0.4
          normalized = let m = magnitude v
                       in if m>1 then v^/m else v
          s' = 80*s

collideBola :: [Bola] -> Bola -> Maybe Double
collideBola others me = if any (`eats'` me) others
                        then Nothing
                        else let eaten = map (view bolMass) $ filter (me `eats'`) others
                             in Just (sum eaten)
        where a `eats'` b = a `eats` b && distBolas a b <= bolRadio a

--------------------------------------------------------------------------------
bolaLogic :: WorldConsts -> (AI, Bola) -> RandomWire (Double, [Bola]) Bola
bolaLogic wc (ai, init) = proc (speed, otros) -> do
        rec
            oldYo <- delay init -< yo
            --Update Mass
            oldRealMass <- delay (view bolMass init) -< realMass
            increment <- mkSF_ (fromJust) . when (isJust) -< collideBola otros oldYo
            realMass <- returnA -< oldRealMass+increment
            varMass <- integralWith min (view bolMass init) -< (realMass, realMass)
            let yo' = set bolMass varMass oldYo

            --Update Position
            v <- ai -< ((wx, wy), yo', otros)
            let v' = mkBolaVec speed yo' v
            pos <- integralVecWith clampCircle initV -< (v', bolRadio yo')
            yo <- returnA -< set bolPos pos yo'
        returnA -< yo
    where initV = view bolPos init
          (wx, wy) = view worlSize wc
          clampCircle r (x, y) = (clamp r (wx-r) x, clamp r (wy-r) y)

-- Maintains the food of the world.
-- Receives all others ais (so eaten food is deleted), returns the food
foodGenerator :: Vector -> RandomWire [Bola] [Bola]
foodGenerator (wx, wy) = proc players -> do
        rec
            oldQFood <- delay 0 -< length food
            newFood <- (genFood . when (<dens) <|> never) -< oldQFood
            food <- dynMulticast -< (players, newFood)
        returnA -< food
    where genFood = periodic prob . fmap foodLogic (mkConstM (randomBola (wx, wy) 1))
          dens = round $ 0.06 * wx * wy / 9  -- 0.06 ~ food per square
          prob = realToFrac $ 1/(0.0003 * wx * wy)

foodLogic :: Bola -> RandomWire [Bola] Bola
foodLogic init = pure init . when (isJust) . mkSF_ (flip collideBola init)

        
integralVecWith :: HasTime t s
    => (w -> Vector -> Vector)  -- ^ Correction function.
    -> Vector                   -- ^ Integration constant (aka start value).
    -> Wire s e m (Vector, w) Vector
integralVecWith correct = loop
    where loop x' = mkPure $ \ds (dx, w) ->
            let dt = realToFrac (dtime ds)
                x  = correct w (x' ^+^ dt*^dx)
            in x' `seq` (Right x', loop x)

        
