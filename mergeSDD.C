/*
  merge output calib objects on Alien
  using AliFileMerger functionality

  Directory with runCalibTrain output: outputDir
  pattern: AliESDfriends_v1.root
  Output file name: CalibObjects.root

  Example:
  .L $ALICE_ROOT/ANALYSIS/CalibMacros/MergeCalibration/merge.C
  merge("alien:///alice/cern.ch/user/j/jotwinow/CalibTrain/output","AliESDfriends_v1.root");
*/
const char* selObj="clistSDDCalib";

void mergeInChunksTXT(const char* mlist, const char* dest, int maxFiles=700);

void mergeSDD(int runMin,int runMax,
	   const char* destDir="mrgPass1", 
	   const char* alienDir="/alice/data/2011/LHC11h/%09d/ESDs/pass1_HLT", 
	   const char* pattern="RecoQAresults.root",  	   
	   Bool_t copyLocal=kFALSE,
	   int timeOut = 10
	   )
{
  for (int r=runMin;r<=runMax; r++) {
    merge(r,destDir,alienDir,pattern,copyLocal,timeOut);
  }
}

void mergeSDD(int run, 
	   const char* destDir="mrgPass1", 
	   const char* alienDir="/alice/data/2011/LHC11h/%09d/ESDs/pass1_HLT", 
	   const char* pattern="RecoQAresults.root",  	   
	   Bool_t copyLocal=kFALSE,
	   int timeOut = 10
	   )
{
  //
  // load libraries
  //
  if (!gGrid) {
    gSystem->Setenv("XRDCLIENTMAXWAIT",Form("%d",timeOut));
    gEnv->SetValue("XNet.RequestTimeout", timeOut);
    gEnv->SetValue("XNet.ConnectTimeout", timeOut);
    gEnv->SetValue("XNet.TransactionTimeout", timeOut);
    TGrid::Connect("alien");
  }
  TFile::SetOpenTimeout(timeOut);
  //
  //
  printf("Merging with chunks copying turned %s\n",copyLocal ? "ON":"OFF");
  gROOT->Macro("LoadLibraries.C");
  //
  TString outputDir = Form(alienDir,run);
  //
  // check if there is such a run
  if (gSystem->AccessPathName(Form("alien://%s",outputDir.Data()))) {
    printf("Directory %s does no exist on alien\n",outputDir.Data());
    return;
  }
  //
  TString outfl = outputDir;
  TString destDirS = destDir;
  if (destDirS.IsNull()) destDir = ".";
  if (!destDirS.EndsWith("/")) destDirS += "/";
  outfl += "_"; 
  outfl += pattern;
  outfl.ReplaceAll("/","_");
  outfl.ReplaceAll(":","");
  outfl.Prepend(destDirS.Data());
  //
  // check if the file already copied
  if (!gSystem->AccessPathName(outfl.Data())) {
    printf("There is already file %s\n",outfl.Data());
    return;
  }
  // check if there is already merged file
  TString merged = Form("alien://%s/%s",outputDir.Data(),pattern);
  if (!gSystem->AccessPathName(merged.Data())) {
    printf("Found merged file %s,\ncopying to %s\n",merged.Data(),outfl.Data());
    TString destMrg = merged;
    Bool_t res = TFile::Cp(merged.Data(), outfl.Data());
    if (!res) printf("Copy failed\n");
    //    return;
  }
  else if (0) {
    printf("No merged data found, will merge chunks\n");
    //    return; //!!!
    //  TString pattS = Form("*%09d*/%s",pattern);
    int nfl = cpTimeOut(outputDir, pattern,timeOut, copyLocal);
    if (nfl<1) {
      printf("No %s chunks in %s\n",pattern, outputDir.Data());
      //    return;
    }
    //
    // local
    //  mergeInChunksTXT("calib.list","CalibObjects.root");
    TH1::AddDirectory(0);
    AliFileMerger merger;
    merger.AddAccept(selObj);
    merger.SetMaxFilesOpen(200);
    merger.IterTXT("calib.list",outfl.Data(),kFALSE);
    //
  }
  // alien
  //merger.IterAlien(outputDir, "CalibObjects.root", pattern);
  //
  printf("Suumary\n");
  // create summary
  int nEv = 0;
  int nTr = 0;
  int nDet=0;
  if (!gSystem->AccessPathName(outfl.Data())) {
    TFile* flres = TFile::Open(outfl.Data());
    if (!flres) return;
    TList* lst = (TList*)gDirectory->Get(selObj);
    if (!lst) return;
    TH1F* hstat = (TH1*)lst->FindObject("hNEvents");
    if (!hstat) return;
    nEv = hstat->GetBinContent(1);
    nTr = hstat->GetBinContent(5);
    for (int isdd=240;isdd<500;isdd++) {
      TProfile* hsdd0 = (TProfile*)lst->FindObject(Form("hpSDDResXvsXD%d_0",isdd));
      TProfile* hsdd1 = (TProfile*)lst->FindObject(Form("hpSDDResXvsXD%d_1",isdd));
      if (hsdd0->GetEntries()>0 || hsdd1->GetEntries()>0) nDet++;
    }
    flres->Close();
    delete flres;
  }
  //  
  ofstream myfile;
  TString outTxt = outfl;
  outTxt.ReplaceAll(".root",".txt");
  myfile.open (outTxt.Data());
  myfile << Form("%d;%d;%d;",nEv,nTr,nDet);
  myfile.close();
  //
  return;
}

int cpTimeOut(const char * searchdir, const char* pattern, Int_t timeOut=10, Bool_t copyLocal)
{
  TString filelist;
  TString command;
  command = Form("find %s/ %s", searchdir, pattern);
  cerr<<"command: "<<command<<endl;
  TGridResult *res = gGrid->Command(command);
  if (!res) return;
  res->Print();
  TIter nextmap(res);
  TMap *map = 0;

  ofstream outputFile;
  outputFile.open(Form("calib.list"));
  Int_t counter=0;

  while((map=(TMap*)nextmap())) 
  {
    TObjString *objs = dynamic_cast<TObjString*>(map->GetValue("turl"));
    if (!objs || !objs->GetString().Length())
    {
      delete res;
      break;
    }
    TString src=Form("%s",objs->GetString().Data());

    TString dst=src;
    Bool_t result = kTRUE;
    if (copyLocal) {
      dst.ReplaceAll("alien:///","");
      dst.ReplaceAll("/","_");
      TTimeStamp s1;
      result = TFile::Cp(src.Data(),dst.Data(),kTRUE);
      TTimeStamp s2;
      AliSysInfo::AddStamp(dst.Data(),counter, result);
    }
    if (result) {
      counter++;
      outputFile << dst.Data()<< endl;
    }
  }
  if (copyLocal) cout<<counter<<" files copied!"<<endl;
  else           cout<<counter<<" files registerd!"<<endl;
  outputFile.close();
  gSystem->Exec("mv syswatch.log syswatch_copy.log");
  return counter;
}

void mergeInChunksTXT(const char* mlist, const char* dest, int maxFiles)
{
  TH1::AddDirectory(0);
  AliFileMerger merger;
  merger.AddAccept(selObj);
  //  merger.SetMaxFilesOpen(999);
  //
  if (maxFiles<2) maxFiles = 2;
  TString filesToMerge = mlist, fileDest = dest;
  if (filesToMerge.IsNull()) {printf("List to merge is not provided\n"); return;}
  if (fileDest.IsNull())     {printf("Merging destination is not provided\n"); return;}
  const char* tmpMerge[3]={"__merge_part0.root","__merge_part1.root","__part_of_calib.list"};
  //
  gSystem->ExpandPathName(filesToMerge);
  ofstream outfile;
  ifstream infile(filesToMerge.Data());
  if (!infile) {printf("No %s file\n",filesToMerge.Data()); return;}
  //
  int currTmp = 0, nfiles = 0, nparts = 0; // counter for number of merging operations
  string line;
  TString lineS;
  while ( !infile.eof() ) {
    getline(infile, line); 
    lineS = line;
    if (lineS.IsNull() || lineS.BeginsWith("#")) continue;
    int st = nfiles%maxFiles;
    if (st==0) { // new chunk should be started
      if (nfiles) { // merge prev. chunk
	outfile.close();
	merger.IterTXT(tmpMerge[2], tmpMerge[currTmp] ,kFALSE);
	printf("Merging to %s | %d files at step %d\n",tmpMerge[currTmp], nfiles,nparts);
      }
      outfile.open(tmpMerge[2], ios::out); // start list for new chunk  
      if (nparts++) {
	printf("Adding previous result %s | %d files %d at part\n",tmpMerge[currTmp], nfiles,nparts);
	outfile << tmpMerge[currTmp] << endl; // result of previous merge goes 1st
      }
      currTmp = (currTmp==0) ? 1:0;         // swap tmp files
    }
    outfile << line << endl;
    nfiles++;
  }
  // merge the rest
  merger.IterTXT(tmpMerge[2], dest ,kFALSE);
  outfile.close();
  infile.close();
  for (int i=0;i<3;i++) gSystem->Exec(Form("if [ -e %s ]; then \nrm %s\nfi",tmpMerge[i],tmpMerge[i]));
  printf("Merged %d files in %d steps\n",nfiles, nparts);
  //
}

