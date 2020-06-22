void CropSDDCal(const char* finp)
{
  TString repl = finp;
  int ind = repl.Last('.');
  if (!ind) exit(1);
  repl.Replace(ind,1,"_cl.");
  //
  TFile* fl = TFile::Open(finp);
  if (!fl) {printf("Failed to open %s\n",finp); exit(1);}
  TList* lst = (TList*)gDirectory->Get("clistSDDCalib");
  if (!lst) {printf("Failed to find clistSDDCalib in %s\n",finp); exit(1);}
  //
  TFile* fo = TFile::Open(repl.Data(),"recreate");
  fo->WriteObject(lst,"clistSDDCalib","kSingleKey");
  fo->Close();
  delete fo;
  if (gSystem->AccessPathName(repl.Data())) {
    printf("Did not manage to write to %s\n",repl.Data());
    exit(1);
  }
  TString cmd=Form("mv %s %s",repl.Data(),finp);
  gSystem->Exec(cmd.Data());
}
