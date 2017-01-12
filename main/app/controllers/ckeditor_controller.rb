class CkeditorController < ApplicationController
  def urlimage
    params.permit!

    image_url = params["src"]
    filename = `uuidgen`
    imagefile = Rails.root + '/tmp/' + filename
    image = ""
    open(image_url) do |image|
      #size = image.size
      #download_size = 0
      open(imagefile, "wb") do |ifile|
        while buf = image.read(1024) do 
          ifile.write buf
          #download_size += 1024
          STDOUT.flush
        end
      end
    end
    
    send_data File.read(imagefile, :mode =>"rb"), :filename =>filename, type: 'image/jpeg;image/jpg;image/gif;image/png', disposition: 'inline'
    
  end
end
