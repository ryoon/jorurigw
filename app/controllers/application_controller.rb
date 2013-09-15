# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  #@@initialized = false
  layout 'empty'
  helper :all
  before_filter :initialize_application
  protect_from_forgery
  trans_sid
  mobile_filter

  def initialize_application
    logger.debug "current thread object-id: #{Thread.current.inspect}, class object-id: #{self.class.object_id}, instance object-id: #{self.object_id}"

    unless self.class.respond_to? :initialized
      self.class.cattr_accessor :initialized
    end

    return if self.class.send(:initialized)

    self.class.send("initialized=", true)

    case Site.mode
    when 'admin'
      self.class.layout 'admin'
      self.class.class_eval { include System::Controller::Admin }
    else
      pp_public_dispatch_log "public ApplicationController#initalize_application:public route"
      self.class.class_eval {
        include Cms::Controller::Public::Layout
        include System::Controller::Public if PUBLIC_LOGIN == 1
      }

      if (site = Cms::Site.find_by_domain(request.env['HTTP_HOST'], :conditions => {:mobile_is => 1}))
        Site.mobile = true
        Site.current_node = Cms::Node.find(2)
      end
    end
  end

  def send_mail(mail_fr, mail_to, subject, message)
    Gw.send_mail(mail_fr, mail_to, subject, message)
  end

  def authentication_error(code=403)
    Page.error = code

    f = File.open(File.join(RAILS_ROOT, 'log', code.to_s + '.log'), 'a')
    f.flock(File::LOCK_EX)
    f.puts "\n" + '====================='
    f.puts Time.now.strftime(' %Y-%m-%d %H:%M:%S') + "\n\n"
    f.puts request.env["REQUEST_URI"]
    f.flock(File::LOCK_UN)
    f.close
    if request.mobile?
      error_file =  "#{RAILS_ROOT}/public/#{code.to_s}_mobile.html"
    else
      error_file =  "#{RAILS_ROOT}/public/#{code.to_s}.html"
    end
    return render(:status => '403 Forbidden', :file => error_file)
  end

  def http_error(code)
    Page.error = code

    f = File.open(File.join(RAILS_ROOT, 'log', code.to_s + '.log'), 'a')
    f.flock(File::LOCK_EX)
    f.puts "\n" + '====================='
    f.puts Time.now.strftime(' %Y-%m-%d %H:%M:%S') + "\n\n"
    f.puts request.env["REQUEST_URI"]
    f.flock(File::LOCK_UN)
    f.close

    return render(:status => '404 Not Found', :file => "#{RAILS_ROOT}/public/#{code.to_s}.html")
  end

  def error(message)
    return respond_to do |format|
      format.html { render :text => "<html><body><h1>#{message}</h1></body></html>" }
      format.xml  { render :xml => "<errors><error>#{message}</error></errors>" }
    end
  end

  def flash_notice(action_description = '処理', done = nil, mode=nil)
    ret = action_description + 'に' + ( done ? '成功' : '失敗' ) + 'しました'
    if mode.nil?
      flash[:notice] = ret
    else
      return ret
    end
  end

  def render_piece(name, piece_param='')
    if piece_param.blank? && name =~ /\[\[piece\/([\w-]+)( +([\w-]+))?\]\]/
      name = $1
      piece_param = nz($3)
    end
    piece = Cms::Piece.new.public
    piece.name = name
    if Site.current_piece = piece.find(:first)
      params_wrk = params
      case nz(piece_param)
      when ''
        params_wrk.delete 'piece_param'
      else
        params_wrk['piece_param'] = piece_param
      end
      piece_data = render_component_as_string :params => params_wrk,
          :controller => Site.current_piece.module + '/public/piece/' + Site.current_piece.controller,
          :action => 'index'
      piece_data = public_show_path("#{Site.current_piece.module}/public/piece/#{Site.current_piece.controller}/index") + piece_data if PUBLIC_SHOW_PATH == 1

      piece_data = replace_directive piece_data if ENABLE_DIRECTIVE_IN_PIECE == 1
      return piece_data
    else
      return PUBLIC_SHOW_PIECE_NOT_FOUND == 1 ? "<div class='notice'>[[piece/#{name}]] not found.</div>" : ''
    end
  end

  around_filter do |controller, action|
    logger.debug "---> IN : controller: #{controller.controller_name}, action: #{controller.action_name}"
    begin
      action.call
    rescue => e
      logger.warn "controller: #{controller.controller_name}, action: #{controller.action_name}: #{e}"
      raise
    ensure
    logger.debug "<--- OUT: controller: #{controller.controller_name}, action: #{controller.action_name}"
    end
  end

  def replace_piece(layout_data)
    h_names = []
    layout_data.scan(/\[\[piece\/([\w-]+)( +([\w-]+))?\]\]/) {|name, dummy, piece_param|
      h_names.push({name => nz(piece_param)})
    }

    h_names.each do |x|
      name = x.keys[0]
      piece_param = x.values[0]
      piece_data = render_piece(name, piece_param)
      piece_call_regex = (piece_param.blank? ? "[[piece/#{name}]]" : %r(\[\[piece/#{name} +#{piece_param}\]\]))
      layout_data = layout_data.gsub(piece_call_regex) { piece_data }
    end
    layout_data
  end

  def replace_directive(piece_data)
    h_names = []
    piece_data.scan(/\[\[(.+)?\]\]/) {|repname|
      h_names.push(repname[0])
    }
    _opt_pp_debug = false
    h_names.each do |x|
      begin
        regex = %r(\[\[#{Regexp.escape(x)}\]\])
        piece_data = piece_data.gsub(regex) {
          case x
          when 'svn_str'
            Gw.svn_str
          when 'today'
            Gw.date_str(Date.today)
          when 'now'
            Gw.datetime_str(Time.now)
          when 'username'
            Site.user.name
          when 'groupname'
            Site.user.groups[0].name
          when 'rails_env'
            RAILS_ENV
          when 'ruby_version'
            RUBY_VERSION
          when 'rails_version'
            Rails.version
          else
            xx = x.split(' ', 2)
            case xx[0]
            when 'eval'
              begin
                eval(xx[1])
              rescue
                pp [:replace_directive_eval_error, e] if _opt_pp_debug
                "[[#{x}]]"
              end
            else
              pp [:replace_directive_no_match_error, xx] if _opt_pp_debug
              "[[#{x}]]"
            end
          end
        }
      rescue RegexpError => e
        pp [:replace_directive_error, e] if _opt_pp_debug
      end
    end
    piece_data
  end

  def replace_eval_in_yaml(piece_data)
    h_names = []
    piece_data.scan(/\#\{(.+)?\}/) {|repname|
      h_names.push(repname[0])
    }
    h_names.each do |x|
      piece_data = piece_data.gsub("\#\{#{x}\}") {
        eval(x) rescue "\#\{#{x}\}]"
      }
    end
    piece_data
  end

  def send_download(filename, stream, options={})
    session_limit_size = nz(options[:session_limit_size], 16.kilobytes)
    mode = session_limit_size < stream.size ? 'file' : 'session'
    mode = 'file' if options[:force_file]
    mode = 'session' if options[:force_session]
    session_data = {}
    session_data[:mode] = mode
    filename = filename.tosjis if !request.user_agent.index("MSIE").nil?
    session_data[:filename] = filename
    case mode
    when 'file'
      tmp_filename = Gw.get_temp_filename(params)
      session_data[:tmp_filename] = tmp_filename
      open(tmp_filename, "w") do |f|
        f.write stream
      end
    when 'session'
      session_data[:stream] = stream
    end
    session[:senddownload] = session_data

    redirect_to download_gw_test_path
  end

  def rescue_action_in_public(e)
      render :file => "#{RAILS_ROOT}/public/error.html", :locals => { :e => e }
  end

end
