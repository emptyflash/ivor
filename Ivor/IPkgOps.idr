module Ivor.IPkgOps

import Ivor.Util
import Ivor.Manifest

import IPkgParser
import IPkgParser.Model

import Lightyear.Strings

%access public export


findIPkgName : String -> Program (Maybe String)
findIPkgName dir = do
  files <- ls dir
  let pkgs = List.filter (Strings.isSuffixOf ".ipkg") files
  pure (head' pkgs)

iPkgNameEntry : IPackageEntry -> Maybe String
iPkgNameEntry (IPkgName name) = Just name
iPkgNameEntry _ = Nothing

iPkgFileToName : IPkgFile -> Maybe String
iPkgFileToName (MkIPkgFile xs) = head' xs >>= iPkgNameEntry
iPkgFileToName _ = Nothing

installIPkg : String -> String -> String -> Dependency -> Program Dependency
installIPkg iPkgDir iPkgFile depsDir dependency = do
  system $ "cd " ++ iPkgDir ++ " && idris --install " ++ iPkgFile ++ " --ibcsubdir " ++ depsDir
    -- ++ " --idrispath " ++ depsDir
  (fullFilename :: _) <- ls $ iPkgDir ++ "/" ++ iPkgFile | _ => do putStrLn "Problem finding ipkg file"
                                                                   pure dependency
  Result iPkgContents <- readFile fullFilename | FError err => do putStrLn $ "Error reading file: " 
                                                                           ++ fullFilename
                                                                  printLn err
                                                                  pure dependency
  case Strings.parse parseIPkgFile iPkgContents of
       Right iPkg => do
         let iPkgName = iPkgFileToName iPkg
         pure $ record { pkgName = iPkgName } dependency
       Left err => do
         putStrLn "Error parsing ipkg file"
         pure dependency


normalizeDirectory : String -> String -> String
normalizeDirectory base dir =
  let baseList = Strings.split (== '/') base
      dirList = Strings.split (== '/') dir
  in if isPrefixOf baseList dirList 
     then foldl (++) "" $ intersperse "/" $ drop (length baseList) dirList
     else dir

fileToModule : String -> String
fileToModule file =
  let splitModules = split (== '/') file
      splitLast = reverse $ drop 1 $ reverse  $ join $ map (split (== '.')) $ take 1 $ reverse splitModules
      dropLast = reverse $ drop 1 $ reverse splitModules
      final = dropLast ++ splitLast
  in foldl (++) "" $ intersperse "." final

iPkgFromManifest : String -> Manifest -> Program IPkgFile
iPkgFromManifest rootDir manifest =  do
  let iPkgName = IPkgName (name manifest)
  modules <- fromMaybe (listAllIdrisFiles rootDir) $ map pure $ modules manifest
  let iPkgModules = IPkgModules $ map (fileToModule . normalizeDirectory rootDir) modules
  let iPkgSrcDir = map IPkgSrcDir $ sourceDirectory manifest
  let iPkgExe = map IPkgExe $ executable manifest
  let iPkgMain = map IPkgMain $ main manifest
  let iPkgOpts = map IPkgOpts $ opts manifest
  let iPkgPkgs = map IPkgPkgs $ sequence $ map pkgName $ dependencies manifest
  pure $ MkIPkgFile $ [iPkgName, iPkgModules] ++ maybeToList iPkgSrcDir
                                              ++ maybeToList iPkgExe
                                              ++ maybeToList iPkgMain
                                              ++ maybeToList iPkgOpts
                                              ++ maybeToList iPkgPkgs

saveAsIPkgFile : String -> Manifest -> Program ()
saveAsIPkgFile dir manifest = do
  iPkgFileString <- iPkgFromManifest dir manifest
  Success <- open (dir ++ "/" ++ name manifest ++ ".ipkg") WriteTruncate
  Success <- writeString $ show iPkgFileString
  close
