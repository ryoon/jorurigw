class Gtalk
  @@lame = 'lame'
  @@gtalk = Rails.root + '/ext/gtalk'
  @@tmp   = '/tmp'

  def make(*args)
    text    = nil
    options = {}

    if args[0].class == String
      text    = args[0]
      options = args[1] || {}
    elsif args[0].class == Hash
      options = args[0]
    end

    if options[:uri]
      options[:uri].sub!(/\/index\.html$/, '/')
      text = load_uri(options[:uri])
    end
    return false unless text

    text = to_utf8(text)
    text = html_to_string(text)
    text = strip_tags(text)
    text = to_gtalk_string(text)

    cnf = Tempfile::new("gtalk_cnf", @@tmp)
    wav = Tempfile::new("gtalk_wav", @@tmp)
    mp3 = Tempfile::new("gtalk_mp3", @@tmp)

    cnf.puts("set Log = No\n")
    cnf.puts("set Speaker = female01\n")
    cnf.puts("set Text = #{text}\n")
    cnf.puts("set SaveWAV = #{wav.path}\n")
    cnf.puts("set Run = EXIT\n")
    cnf.close

    require 'shell'
    sh = Shell.cd(@@gtalk)

    res = sh.system("./gtalk -C ./ssm.conf < #{cnf.path}")
    res.to_s

    if FileTest.exists?(wav.path)
      res = sh.system("#{@@lame} --scale 8 #{wav.path} #{mp3.path}")
      res.to_s
    end

    [cnf.path, wav.path, "#{wav.path}.info"].each do |file|
      FileUtils.rm(file) if FileTest.exists?(file)
    end

    if FileTest.exists?(mp3.path)
      @mp3 = mp3
    end
  end

  def output
    if FileTest.exists?(@mp3.path)
      return {:path => @mp3.path, :mime_type => 'audio/mp3'}
    end
    return nil
  end

private
  def to_gtalk_string(text)
    spacer = '(\r\n|\n|\r|\t| |　|\/|／)'
    text.gsub!(/#{spacer}{2,}/m, '。')
    text.gsub!(/#{spacer}+/m, '、')
    text.gsub!(/&[0-9a-zA-Z]+;/im, '')
    text.tr!("0-9a-zA-Z", "０-９ａ-ｚＡ-Ｚ")
    text.tr!("-", "－")
    return text
  end

  def to_utf8(text)
    require 'nkf'
    text = NKF.nkf('-w', text)
    return text
  end

  def html_to_string(text)

    text.sub!(/.*<body.*?>(.*)<\/body.*/im, '\1')
    ['script', 'style', 'rp', 'rt'].each do |element|
      text.gsub!(/<#{element}.*?>.*?<\/#{element}>/im, '')
    end

    text.gsub!(/<!-- skip reading -->.*?<!-- \/skip reading -->/im, '')

    text.gsub!(/<img .*?>/i) do |m|
      alt = nil
      if m =~ / title=".*"/
        alt = m.sub(/.* title="(.*?)".*/i, '\1')
      elsif m =~ / alt=".*"/
        alt = m.sub(/.* alt="(.*?)".*/i, '\1')
      end
      alt ? "イメージ、#{alt}、" : ''
    end
    return text
  end

  def strip_tags(text)
    text.sub!(/<[^<>]*>/, '') while /<[^<>]*>/ =~ text

    return text
  end

  def load_uri(uri)
    status  = nil;
    content = ''

    begin
      require 'open-uri'
      open(uri) do |f|
        status = f.status[0].to_i
        f.each_line {|line| content += line}
      end
    rescue
      status = 404
    end

    return status == 200 ? content : nil
  end
end