#if !defined(__CINT__) || defined(__MAKECINT__)
#include <TMath.h>
#include <TH1.h>
#include <TH2.h>
#include <TF1.h>
#include <TProfile.h>
#include <TSpline.h>
#include <TCanvas.h>
#include <TStyle.h>
#include <TFile.h>
#include <TGrid.h>
#include <TGraphErrors.h>
#include <TSystem.h>
#include <TLatex.h>
#include <TMinuit.h>
#include <TList.h>
#endif


void RemoveSlope(const char* finp, const char* modf="_NoSlp")
{
    
    
    printf("Removing Slope");
  TString name0 = "clistITSAlignQA";
  TString name1 = "clistSDDCalib";
  TString finpS = finp;
  gSystem->ExpandPathName(finpS);
  TFile* flinp = TFile::Open(finpS.Data());
  if (!flinp) {printf("Failed to open qa output %s\n",finpS.Data()); exit(1);}
  if (flinp->Get("ITSAlignQA")) {
    flinp->cd("ITSAlignQA");
  }
  TString nameL = name0;
  TList *qa = (TList*)gDirectory->Get(name0.Data());
  if (!qa) {
    qa = (TList*)gDirectory->Get(name1.Data());
    if (!qa) {printf("Did not find neither %s nor %s in qa output %s\n",name0.Data(),name1.Data(),finpS.Data()); exit(1);}
    nameL = name1;
  }
  //
  TF1* fn = new TF1("fn","pol1",-1000,40000);
  for (int is=240;is<500;is++) {
    for (int ix=0;ix<2;ix++) {
      TProfile* hxx = (TProfile*)qa->FindObject(Form("hpSDDResXvsXD%d_%d",is,ix));
      if (hxx->GetEntries()<1000) continue;
      hxx->Fit(fn,"0qN","",4000,31000);
      fn->SetParameter(0,0);
      for (int i=1;i<=hxx->GetNbinsX();i++) {
	double x=hxx->GetBinCenter(i);
	double y=fn->Eval(x);
	double y0=hxx->GetBinContent(i);
	int nn=hxx->GetBinEntries(i);
	double del=(y0-y)*nn;
	hxx->SetBinContent(i,del);}
    }
  }
  //
  TString outfS = finpS;
  int indx = outfS.Index(".root");
  outfS.Insert(indx,modf);
  TFile* flout = TFile::Open(outfS.Data(),"recreate");
  flout->WriteObject(qa,nameL.Data(),"kSingleKey");
  flout->Close();
  delete flout;
}
