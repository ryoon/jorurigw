module System::Controller::Scaffold
  def self.included(mod)
    mod.before_filter :initialize_scaffold
  end

  def initialize_scaffold

  end

  def edit
    show
  end

protected
  def _index(items)
    respond_to do |format|
      format.html { render }
      format.xml  { render :xml => to_xml(items) }
    end
  end

  def _show(item)
    return send(params[:do], item) if params[:do]

    respond_to do |format|
      format.html { render }
      format.xml  { render :xml => to_xml(item) }
      format.json { render :text => item.to_json }
      format.yaml { render :text => item.to_yaml }
    end
  end

  def _create(item, options = {})
    raise ArgumentError, 'public call では必ず :success_redirect_uri を指定してください' if Site.mode == 'public' && options[:success_redirect_uri].nil?
    respond_to do |format|
      validation = nz(options[:validation], true)
      if item.creatable? && item.save(validation)
        options[:after_process].call if options[:after_process]
        system_log.add(:item => item, :action => 'create')

        location = nz(options[:success_redirect_uri], url_for(:action => :index))
        location.sub!(/\[\[id\]\]/, "#{item.id}") if options[:no_update_id].nil?
        status = params[:_created_status] || :created
        flash[:notice] = options[:notice] || '登録処理が完了しました'
        format.html { redirect_to location }
        format.xml  { render :xml => to_xml(item), :status => status, :location => location }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def _update(item, options = {})
    raise ArgumentError, 'public call では必ず :success_redirect_uri を指定してください' if Site.mode == 'public' && options[:success_redirect_uri].nil?
    respond_to do |format|
      validation = nz(options[:validation], true)
      if item.editable? && item.save(validation)
        options[:after_process].call if options[:after_process]
        system_log.add(:item => item, :action => 'update')

        location = nz(options[:success_redirect_uri], url_for(:action => :index))
        location.sub!(/\[\[id\]\]/, "#{item.id}") if options[:no_update_id].nil?
        send_recognition_mail(item) if defined?(item.recognizable?) && item.recognizable?
        flash[:notice] = options[:notice] || '更新処理が完了しました'
        format.html { redirect_to location }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def send_recognition_mail(item)
    mail_fr = 'admin@192.168.0.2'
    subject = '【' + Site.title + '】 承認依頼'
    message = '下記URLから承認処理をお願いします。' + "\n\n" +
      url_for(:action => :show)

    item.recognizers.each do |_recognizer|
      mail_to = _recognizer.user.email
      mailer = Cms::Lib::Mail::Smtp.deliver_recognition(mail_fr, mail_to, subject, message)
    end
  end

  def _destroy(item, options = {})
    raise ArgumentError, 'public call では必ず :success_redirect_uri を指定してください' if Site.mode == 'public' && options[:success_redirect_uri].nil?
    respond_to do |format|
      if item.deletable? && item.destroy
        options[:after_process].call if options[:after_process]
        system_log.add(:item => item, :action => 'destroy')

        flash[:notice] = options[:notice] || '削除処理が完了しました'
        format.html { redirect_to nz(options[:success_redirect_uri], url_for(:action => :index)) }
        format.xml  { head :ok }
      else
        flash[:notice] = '削除できません'
        format.html { render :action => :show }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
    end
  end

end