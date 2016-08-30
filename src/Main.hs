
-- | OnlineATPs: A program for proving first-order theorems written in the
-- | TPTP format using SystemOnTPTP

{-# LANGUAGE MultiWayIf          #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE UnicodeSyntax       #-}


module Main
  ( main  -- Required by Haddock.
  ) where

import OnlineATPs.Consult
  ( getOnlineATPs
  , getResponseSystemOnTPTP
  , getSystemATP
  , getSystemOnTPTP
  , Msg
  )

import OnlineATPs.CheckOutput (checkTheoremSync)
import OnlineATPs.Options
  ( Options
    ( optATP
    , optATPList
    , optHelp
    , optInputFile
    , optOnlyCheck
    , optVersion
    , optVersionATP
    )
  , printUsage
  , processOptions
  )

import OnlineATPs.SystemATP
  ( SystemATP(..)
  ,  printListOnlineATPs
  , getNameVersion
  )


import           OnlineATPs.SystemOnTPTP    (SystemOnTPTP)

import           Control.Monad              (unless)
import qualified Data.ByteString.Lazy       as L
import qualified Data.ByteString.Lazy.Char8 as C
import           OnlineATPs.Utils.Monad     (die)
import           OnlineATPs.Utils.Version   (progNameVersion)
import           System.Directory           (doesFileExist)
import           System.Environment         (getArgs)
import           System.Exit                (exitFailure, exitSuccess)

main ∷ IO ()
main = do
  args ← getArgs
  opts ← case processOptions args of
    Left err → die err
    Right o  → return o

  if  | optHelp opts → printUsage >> exitSuccess

      | optVersion opts → do
        v ← progNameVersion
        putStrLn v  >> exitSuccess

      | optATPList opts → do
        atps ← getOnlineATPs opts
        printListOnlineATPs atps  >> exitSuccess

      | not (null $ optVersionATP opts) → do
          atp ∷ SystemATP  ← getSystemATP opts
          case atp of
            NoSystemATP → die "unknown ATP name. Check --list-atps"
            _           → putStrLn (getNameVersion atp) >> exitSuccess
      | otherwise → do

          file ← case optInputFile opts of
            Nothing → die "missing input file (try --help)"
            Just f  → return f

          isFile ← doesFileExist file
          unless isFile $ die "the file doesn't exist"

          _ ← case optATP opts of
            [] → die "missing --atp=NAME (try --help)"
            o  → return o

          form ∷ Either Msg SystemOnTPTP ← getSystemOnTPTP opts

          case form of
            Left msg   → putStrLn msg >> exitFailure

            Right spec →
              if optOnlyCheck opts
                then do

                  answer ∷ String ← checkTheoremSync spec
                  putStrLn answer >> exitSuccess

                else do

                  response ∷ L.ByteString ← getResponseSystemOnTPTP spec
                  C.putStrLn response >> exitSuccess
