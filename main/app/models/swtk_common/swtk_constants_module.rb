module SwtkConstantsModule
  module SwtkConstants
    CkpDepth = 100
    CkpStep = 3
    RidDepth = 100
    RidStep = 3
    AlphabetDownCaseArr = [*'a'..'z']
    AlphabetUpCaseArr = [*'A'..'Z']
    NumberArr = [*'0'..'9']
    #UploadPrefix = Rails.root.to_s + "/uploads/"
    UploadPrefix = "/paper_files_warehouse/"
    DefaultPage = 1
    DefaultRows = 10
    DefaultSheetPassword = "forbidden_by_k12ke"
    MyDomain = "www.k12ke.com"
    CDNDomain = "cdn.k12ke.com"
    CDNVersion1_0 = "000016090"
    CDNVersion1_1 = "00016110"
  end
end