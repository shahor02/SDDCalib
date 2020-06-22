{  
  cout<<endl;
  cout<<" *******************************************"<<endl;
  cout<<" *                                         *"<<endl;
  cout<<" *        W E L C O M E  to  R O O T       *"<<endl;
  cout<<" *                                         *"<<endl;
  //cout<<" *   Version  4.04/02b       3 June 2005   *"<<endl;
  //cout<<" *   Version   5.02/00      28 June 2005   *"<<endl;
  //cout<<" *   Version   5.06/00   30 October 2005   *"<<endl;
  //cout<<" *     Version "<<gROOT->GetVersion()<<"                       *"<<endl;
  //cout<<" *                                         *"<<endl;
  //cout<<" *  You are welcome to visit our Web site  *"<<endl;
  //cout<<" *          http://root.cern.ch            *"<<endl;
  //cout<<" *                                         *"<<endl;
  cout<<" *******************************************"<<endl;
  cout<<endl;
  cout<<" Version "<<gROOT->GetVersion()<<endl;
  cout<<endl;
  
  //if (gClassTable->GetID("ktJet") < 0)
    //gSystem->Load("libKtJet.so");
  gSystem->SetIncludePath("-I. -I$ROOTSYS/include -I$ALICE_ROOT -I$ALICE_ROOT/include -I$ALICE_ROOT/ITS -I$ALICE_ROOT/TPC -I$ALICE_ROOT/CONTAINERS -I$ALICE_ROOT/STEER -I$ALICE_ROOT/STEER/CDB -I$ALICE_ROOT/TRD -I$ALICE_ROOT/macros -I$ALICE_ROOT/ANALYSIS -I$ALICE_ROOT/PWGHF -I$ALICE_ROOT/PWGHF/base -I$ALICE_ROOT/PWGHF/vertexingHF -g");
  //  gSystem->SetIncludePath("-I -I$ROOTSYS/include -I$ALICE_ROOT -I$ALICE_ROOT/include  -g");

   
// // Load analysis framework libraries
    gSystem->Load("libVMC");

    gSystem->Load("libTree.so");
    gSystem->Load("libGeom.so");
    gSystem->Load("libPhysics.so");
    gSystem->Load("libVMC.so");
    gSystem->Load("libMinuit.so");
   gSystem->Load("libSTEERBase");
   gSystem->Load("libESD");
   gSystem->Load("libAOD");
   gSystem->Load("libANALYSIS");
   gSystem->Load("libANALYSISalice");
    gSystem->Load("libANALYSIScalib");

   gSystem->Load("libCORRFW");
    gSystem->Load("libANALYSISalice.so");
    gSystem->Load("libANALYSIScalib.so");
    gSystem->Load("libTENDER.so");
    
  //   // Add aditional AliRoot libraries
//   gSystem->Load("libEMCALUtils.so");
//   gSystem->Load("libPHOSUtils.so");
//   gSystem->Load("libPWG4PartCorrBase.so");
//   gSystem->Load("libPWG4PartCorrDep.so");
   
 
  cout<<"======= The include path is ==========="<<endl;
  cout<< gSystem->GetIncludePath()<<endl;

  if (gClassTable->GetID("AliRun") > 0) {
    cout<<"      AliROOT"<<endl; cout<<endl;}
  
    

    
    

    
  // if (gClassTable->GetID("ktJet") > 0) {
  // cout<<" (including ktJet libraries)"<<endl;
  // cout<<endl; }
  

 //    gROOT->Macro("$ALICE_ROOT/PWGHF/vertexingHF/macros/LoadLibraries.C");
}

