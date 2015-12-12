{-# LANGUAGE TemplateHaskell #-}
-- |
-- Module:     AgarSimu.PreFab
-- Copyright:  (c) 2015 Martin Villagra
-- License:    BSD3
-- Maintainer: Martin Villagra <mvillagra0@gmail.com>

module AgarSimu.PreFab
    ( -- * Random
      randomW,
      randomWR,    
      randomDir,

      -- * Basic Wires 
      go,    
      stop    
    )
    where

import Control.Lens hiding (at, perform, wrapped)
import Control.Wire
import Control.Monad.Random
import AgarSimu.Utils
import AgarSimu.PublicEntities
import Prelude hiding ((.), id)

randomW :: (MonadRandom m, Random b) => Wire s e m a b
randomW = mkGen_' $ const getRandom
randomWR :: (MonadRandom m, Random b) => Wire s e m (b, b) b
randomWR = mkGen_' $ getRandomR

randomDir :: RandomWire a Vector
randomDir = go . randomWR . pure (-pi, pi)

go :: RandomWire Double Vector
go = arr sin &&& arr cos

stop :: RandomWire a Vector
stop = pure (0, 0)
