class Cms::Tool::TalksController < ApplicationController
  def read
    @skip_layout = true

    path = '/' + params[:path].join('/')
    path.gsub!(/\/+/, '/')
    if path.slice(0, 1) == '/'
      path = path.slice(1, path.size)
    end

    uri = Site.uri(:http => true) + path

    gtalk = Gtalk.new
    gtalk.make :uri => uri

    file = gtalk.output

    f = open(file[:path])
    send_data(f.read, {:type => file[:path], :filename => 'sound.mp3', :disposition => 'inline'})
    f.close

    return :text => ''
  end
end
