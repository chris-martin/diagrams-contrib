{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Diagrams.TwoD.Layout.Grid
-- Copyright   :  (c) 2014 Pontus Granström
-- License     :  BSD-style (see LICENSE)
-- Maintainer  :  pnutus@gmail.com
--
-- Functions for effortlessly putting lists of diagrams in a grid layout.
--
-----------------------------------------------------------------------------

module Diagrams.TwoD.Layout.Grid
    (
      gridCat
    , gridCat'
    , gridSnake
    , gridSnake'
    , gridWith

    , sameBoundingRect
    , sameBoundingSquare

    ) where

import           Data.List        (maximumBy)
import           Data.Ord         (comparing)
import           Data.Typeable

import           Data.List.Split  (chunksOf)

import           Diagrams.Prelude

-- * Grid Layout

-- | Puts a list of diagrams in a grid, left-to-right, top-to-bottom.
--   The grid is as close to square as possible.
--
-- > import Diagrams.TwoD.Layout.Grid
-- > gridCatExample = gridCat $ map (flip regPoly 1) [3..10]
--
-- <<#diagram=gridCatExample&width=200>>

gridCat
  :: (Backend b V2 n, Renderable (Path V2 n) b, RealFloat n, Typeable n)
  => [Diagram b V2 n]
  -> Diagram b V2 n
gridCat diagrams = gridCat' (intSqrt $ length diagrams) diagrams

-- | Same as 'gridCat', but with a specified number of columns.
--
-- > import Diagrams.TwoD.Layout.Grid
-- > gridCatExample' = gridCat' 4 $ map (flip regPoly 1) [3..10]
--
-- <<#diagram=gridCatExample'&width=200>>

gridCat'
  :: (Backend b V2 n, Renderable (Path V2 n) b, RealFloat n, Typeable n)
  => Int -> [Diagram b V2 n]
  -> Diagram b V2 n
gridCat' = gridAnimal id

-- | Puts a list of diagrams in a grid, alternating left-to-right
--   and right-to-left. Useful for comparing sequences of diagrams.
--   The grid is as close to square as possible.
--
-- > import Diagrams.TwoD.Layout.Grid
-- > gridSnakeExample = gridSnake $ map (flip regPoly 1) [3..10]
--
-- <<#diagram=gridSnakeExample&width=200>>

gridSnake
  :: (Backend b V2 n, Renderable (Path V2 n) b, Typeable n, RealFloat n)
  => [Diagram b V2 n]
  -> Diagram b V2 n
gridSnake diagrams = gridSnake' (intSqrt $ length diagrams) diagrams

-- | Same as 'gridSnake', but with a specified number of columns.
--
-- > import Diagrams.TwoD.Layout.Grid
-- > gridSnakeExample' = gridSnake' 4 $ map (flip regPoly 1) [3..10]
--
-- <<#diagram=gridSnakeExample'&width=200>>

gridSnake'
  :: (Backend b V2 n, Renderable (Path V2 n) b, RealFloat n, Typeable n)
  => Int -> [Diagram b V2 n]
  -> Diagram b V2 n
gridSnake' = gridAnimal (everyOther reverse)

-- | Generalisation of gridCat and gridSnake to not repeat code.
gridAnimal
  :: (Backend b V2 n, Renderable (Path V2 n) b, TypeableFloat n)
  => ([[Diagram b V2 n]] -> [[Diagram b V2 n]]) -> Int -> [Diagram b V2 n]
  -> Diagram b V2 n
gridAnimal rowFunction cols = vcat . map hcat . rowFunction
    . chunksOf cols . sameBoundingRect . padList cols mempty

-- | `gridWith f (cols, rows)` uses `f`, a function of two
--   zero-indexed integer coordinates, to generate a grid of diagrams
--   with the specified dimensions.
gridWith
  :: (Backend b V2 n, Renderable (Path V2 n) b, RealFloat n, Typeable n)
  => (Int -> Int -> Diagram b V2 n) -> (Int, Int)
  -> Diagram b V2 n
gridWith f (cols, rows) = gridCat' cols diagrams
  where
    diagrams = [ f x y | y <- [0..rows - 1] , x <- [0..cols - 1] ]

-- * Bounding boxes

-- | Make all diagrams have the same bounding square,
--   one that bounds them all.
sameBoundingSquare
  :: forall b n. (Backend b V2 n, Renderable (Path V2 n) b, Ord n, RealFloat n, Typeable n)
  => [Diagram b V2 n]
  -> [Diagram b V2 n]
sameBoundingSquare diagrams = map frameOne diagrams
  where
    biggest = maximumBy (comparing maxDim) diagrams
    maxDim diagram = max (width diagram) (height diagram)
    centerPoint = center2D biggest
    padSquare = (square (maxDim biggest) :: D V2 n) # phantom
    frameOne = atop padSquare . moveOriginTo centerPoint


-- | Make all diagrams have the same bounding rect,
--   one that bounds them all.
sameBoundingRect
  :: forall n b. (Backend b V2 n, Renderable (Path V2 n) b, Ord n, RealFloat n, Typeable n)
  => [Diagram b V2 n]
  -> [Diagram b V2 n]
sameBoundingRect diagrams = map frameOne diagrams
  where
    widest = maximumBy (comparing width) diagrams
    tallest = maximumBy (comparing height) diagrams
    (xCenter :& _) = coords (center2D widest)
    (_ :& yCenter) = coords (center2D tallest)
    padRect = (rect (width widest) (height tallest) :: D V2 n) # phantom
    frameOne = atop padRect . moveOriginTo (xCenter ^& yCenter)

-- * Helper functions.

intSqrt :: Int -> Int
intSqrt = round . sqrt . (fromIntegral :: Int -> Float)

everyOther :: (a -> a) -> ([a] -> [a])
everyOther f xs = zipWith ($) (cycle [id, f]) xs

padList :: Int -> a -> [a] -> [a]
padList m padding xs = xs ++ replicate (mod (- length xs) m) padding