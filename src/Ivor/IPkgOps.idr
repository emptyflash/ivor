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


ipkgInstallDir : Dependency -> String -> Program String
ipkgInstallDir dependency depsDir = do
  let packageName = fromMaybe "" $ pkgName dependency
  let installDir = depsDir ++ "/" ++ packageName
  pure installDir

updatePkgName : String -> String -> Dependency -> Program Dependency
updatePkgName iPkgDir iPkgFile dependency = do
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
         putStrLn $ "Error parsing ipkg file: " ++ show err
         pure dependency

installIPkg : String -> String -> String -> Dependency -> Program Dependency
installIPkg iPkgDir iPkgFile depsDir dependency = do
  newDependency <- updatePkgName iPkgDir iPkgFile dependency
  installDir <- ipkgInstallDir newDependency depsDir
  system $ "rm -rf " ++ installDir -- Sometimes idris build fails if the ibcsubdir already exists
  system $ "cd " ++ iPkgDir ++ " && IDRIS_LIBRARY_PATH=" ++ depsDir ++ " idris --build " ++ iPkgFile ++ " --ibcsubdir " ++ installDir
  pure newDependency


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
  let srcDir = fromMaybe rootDir $ map (\sd => rootDir ++ "/" ++ sd) $ sourceDirectory manifest
  modules <- fromMaybe (listAllIdrisFiles srcDir) $ map pure $ modules manifest
  let iPkgModules = IPkgModules $ map (fileToModule . normalizeDirectory srcDir) modules
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
