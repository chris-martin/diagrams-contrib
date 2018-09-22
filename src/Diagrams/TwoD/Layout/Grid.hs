{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeFamilies          #-}

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

import           Data.List.Split  (chunksOf)

import           Diagrams.Prelude

-- * Grid Layout

-- | Puts a list of diagrams in a grid, left-to-right, top-to-bottom.
--   The grid is as close to square as possible.
--
-- > import Diagrams.TwoD.Layout.Grid
-- > gridCatExample = gridCat $ map (flip regPoly 1) [3..10]
--
-- <<diagrams/src_Diagrams_TwoD_Layout_Grid_gridCatExample.svg#diagram=gridCatExample&width=200>>

gridCat
  :: [Diagram V2] -> Diagram V2
gridCat diagrams = gridCat' (intSqrt $ length diagrams) diagrams

-- | Same as 'gridCat', but with a specified number of columns.
--
-- > import Diagrams.TwoD.Layout.Grid
-- > gridCatExample' = gridCat' 4 $ map (flip regPoly 1) [3..10]
--
-- <<diagrams/src_Diagrams_TwoD_Layout_Grid_gridCatExample'.svg#diagram=gridCatExample'&width=200>>

gridCat' :: Int -> [Diagram V2] -> Diagram V2
gridCat' = gridAnimal id

-- | Puts a list of diagrams in a grid, alternating left-to-right
--   and right-to-left. Useful for comparing sequences of diagrams.
--   The grid is as close to square as possible.
--
-- > import Diagrams.TwoD.Layout.Grid
-- > gridSnakeExample = gridSnake $ map (flip regPoly 1) [3..10]
--
-- <<diagrams/src_Diagrams_TwoD_Layout_Grid_gridSnakeExample.svg#diagram=gridSnakeExample&width=200>>

gridSnake :: [Diagram V2] -> Diagram V2
gridSnake diagrams = gridSnake' (intSqrt $ length diagrams) diagrams

-- | Same as 'gridSnake', but with a specified number of columns.
--
-- > import Diagrams.TwoD.Layout.Grid
-- > gridSnakeExample' = gridSnake' 4 $ map (flip regPoly 1) [3..10]
--
-- <<diagrams/src_Diagrams_TwoD_Layout_Grid_gridSnakeExample'.svg#diagram=gridSnakeExample'&width=200>>

gridSnake' :: Int -> [Diagram V2] -> Diagram V2
gridSnake' = gridAnimal (everyOther reverse)

-- | Generalisation of gridCat and gridSnake to not repeat code.
gridAnimal
  :: ([[Diagram V2]] -> [[Diagram V2]]) -> Int -> [Diagram V2]
  -> Diagram V2
gridAnimal rowFunction cols = vcat . map hcat . rowFunction
    . chunksOf cols . sameBoundingRect . padList cols mempty

-- | `gridWith f (cols, rows)` uses `f`, a function of two
--   zero-indexed integer coordinates, to generate a grid of diagrams
--   with the specified dimensions.
gridWith :: (Int -> Int -> Diagram V2) -> (Int, Int) -> Diagram V2
gridWith f (cols, rows) = gridCat' cols diagrams
  where
    diagrams = [ f x y | y <- [0..rows - 1] , x <- [0..cols - 1] ]

-- * Bounding boxes

-- | Make all diagrams have the same bounding square,
--   one that bounds them all.
sameBoundingSquare :: [Diagram V2] -> [Diagram V2]
sameBoundingSquare diagrams = map frameOne diagrams
  where
    biggest        = maximumBy (comparing maxDim) diagrams
    maxDim diagram = max (width diagram) (height diagram)
    centerP        = centerPoint biggest
    padSquare      = (square (maxDim biggest) :: Path V2 Double) # phantom
    frameOne       = (<>) padSquare . moveOriginTo centerP
    -- ATOP!!


-- | Make all diagrams have the same bounding rect,
--   one that bounds them all.
sameBoundingRect
  :: [Diagram V2] -> [Diagram V2]
sameBoundingRect diagrams = map frameOne diagrams
  where
    widest = maximumBy (comparing width) diagrams
    tallest = maximumBy (comparing height) diagrams
    P2 xCenter _ = centerPoint widest
    P2 _ yCenter = centerPoint tallest
    padRect = (rect (width widest) (height tallest) :: Path V2 Double) # phantom
    frameOne = (<>) padRect . moveOriginTo (P2 xCenter yCenter)
    -- ATOP!!

-- * Helper functions.

intSqrt :: Int -> Int
intSqrt = round . sqrt . (fromIntegral :: Int -> Float)

everyOther :: (a -> a) -> [a] -> [a]
everyOther f = zipWith ($) (cycle [id, f])

padList :: Int -> a -> [a] -> [a]
padList m padding xs = xs ++ replicate (mod (- length xs) m) padding
