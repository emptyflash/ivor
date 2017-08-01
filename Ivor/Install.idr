module Ivor.Install

import Ivor.Util
import public Ivor.Config

import IPkgParser
import IPkgParser.Model

import Lightyear.Strings

%access public export


makePackagesDir : Program String 
makePackagesDir = do
  let pkgDir = idrisAppDir ++ "/packages"
  system $ "mkdir -p " ++ pkgDir
  pure pkgDir

makeDepsDir : Program String
makeDepsDir = do
  wd <- pwd
  let depsDir = wd ++ "/deps"
  system $ "mkdir -p " ++ depsDir
  pure depsDir

fileExists : String -> Program Bool
fileExists dir = do
  result <- system $ "test -e " ++ dir
  pure (result == 0)

findIpkgName : String -> Program (Maybe String)
findIpkgName dir = do
  files <- ls dir
  let pkgs = List.filter (Strings.isSuffixOf ".ipkg") files
  pure (head' pkgs)

ipkgNameEntry : IPackageEntry -> Maybe String
ipkgNameEntry (IPkgName name) = Just name
ipkgNameEntry _ = Nothing

ipkgFileToName : IPkgFile -> Maybe String
ipkgFileToName (MkIPkgFile xs) = head' xs >>= ipkgNameEntry
ipkgFileToName _ = Nothing

installIpkg : String -> String -> String -> Dependency -> Program Dependency
installIpkg ipkgDir ipkgFile depsDir dependency = do
  system $ "cd " ++ ipkgDir ++ " && idris --install " ++ ipkgFile ++ " --ibcsubdir " ++ depsDir
  (fullFilename :: _) <- ls $ ipkgDir ++ "/" ++ ipkgFile | _ => do putStrLn "Problem finding ipkg file"
                                                                   pure dependency
  Result ipkgContents <- readFile fullFilename | FError err => do putStrLn $ "Error reading file: " 
                                                                           ++ fullFilename
                                                                  printLn err
                                                                  pure dependency
  case Strings.parse parseIPkgFile ipkgContents of
       Right ipkg => do
         let ipkgName = ipkgFileToName ipkg
         pure $ record { pkgName = ipkgName } dependency
       Left err => do
         putStrLn "Error parsing ipkg file"
         pure dependency

installMakefile : String -> Program Int
installMakefile dir = system $ "cd " ++ dir ++ " && make install"

cloneRepo : String -> String -> String -> Program Int
cloneRepo pkgsDir repoUrl repoDir =
  system $ "cd " ++ pkgsDir ++ " && git clone " ++ repoUrl ++ " " ++ repoDir

fetchRepo : String -> Program Int
fetchRepo fullDir =
  system $ "cd " ++ fullDir ++ " && git fetch"

applyGitVersion : String -> String -> Program Int
applyGitVersion fullDir version =
  system $ "cd " ++ fullDir ++ " && git checkout " ++ version

updateRepo : String -> String -> Maybe String -> Program String
updateRepo pkgsDir repo maybeVersion = do
  let repoDir = dirFromRepo repo
  let fullDir = pkgsDir ++ "/" ++ repoDir
  if !(fileExists fullDir)
     then fetchRepo fullDir
     else cloneRepo pkgsDir (githubUrl repo) repoDir
  case maybeVersion of
       Just version => do applyGitVersion fullDir version; pure ()
       Nothing => pure ()
  pure fullDir

installFromGithub : Dependency -> Program Dependency
installFromGithub dep = do
  let repo = name dep
  let maybeVersion = version dep
  pkgsDir <- makePackagesDir
  depsDir <- makeDepsDir
  fullRepo <- updateRepo pkgsDir repo maybeVersion
  Just ipkg <- findIpkgName fullRepo | Nothing => do putStrLn $ "No .ipkg found in " ++ repo
                                                     pure dep
  installIpkg fullRepo ipkg depsDir dep

installConfig : String -> Program Int
installConfig configFile = do
  Right config <- parseConfigFile configFile | Left err => do putStrLn err; pure 1
  printLn $ map name $ dependencies $ config
  results <- mapE (\t => installFromGithub t) (dependencies config)
  pure 0

