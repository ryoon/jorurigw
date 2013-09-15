ActionController::Routing::Routes.draw do |map|
  public = Proc.new do |_map, mod, path, controller, options|
    options[:controller] = "#{mod}/public/#{controller}"
    _map.connect "/_public/#{mod}/#{path}", options
  end
  def gw2(_map, mod, resource, options={})
    opt = options
    opt[:a_p] = 'admin'
    gw_core _map, mod, resource, opt
  end
  def gwp2(_map, mod, resource, options={})
    opt = options
    opt[:a_p] = 'public'
    gw_core _map, mod, resource, opt
  end
  def gw_core(_map, mod, resource, options={})
    opt = options
    a_p = opt[:a_p]
    controller = options[:controller]||= resource.to_s
    mod_prefix = options[:mod_prefix]
    path_prefix = options[:path_prefix]||= ''
    opt[:controller] = mod_prefix.nil? ? Gw.join([mod, a_p, controller], '/') : Gw.join([mod_prefix, a_p, mod, controller], '/')
    opt[:namespace] = ""
    opt[:path_prefix] = Gw.join(["_#{a_p}", mod_prefix, "#{mod}#{path_prefix}"], '/')
    opt[:name_prefix] = Gw.join([mod_prefix, mod], '_') + '_'
    opt[:collection] = opt[:collection]||={}
    opt[:member] = opt[:member]||=[]
    _map.resources resource, options
  end

# --------------------------------------------------------------------------
# 添付ファイルダウンロード　共通
  def admin_attaches(map, sys)
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code", :controller => "attaches/admin/#{sys}", :action => 'download'
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code/:filename", :controller => "attaches/admin/#{sys}", :action => 'download'
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code/:filename.:fm1", :controller => "attaches/admin/#{sys}", :action => 'download'
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code/:filename.:fm1.:fm2", :controller => "attaches/admin/#{sys}", :action => 'download'
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code/:filename.:fm1.:fm2.:fm3", :controller => "attaches/admin/#{sys}", :action => 'download'
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code/:filename.:fm1.:fm2.:fm3.:fm4", :controller => "attaches/admin/#{sys}", :action => 'download'
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code/:filename.:fm1.:fm2.:fm3.:fm4.:fm5", :controller => "attaches/admin/#{sys}", :action => 'download'
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code/:filename.:fm1.:fm2.:fm3.:fm4.:fm5.:fm6", :controller => "attaches/admin/#{sys}", :action => 'download'
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code/:filename.:fm1.:fm2.:fm3.:fm4.:fm5.:fm6.:fm7", :controller => "attaches/admin/#{sys}", :action => 'download'
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code/:filename.:fm1.:fm2.:fm3.:fm4.:fm5.:fm6.:fm7.:fm8", :controller => "attaches/admin/#{sys}", :action => 'download'
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code/:filename.:fm1.:fm2.:fm3.:fm4.:fm5.:fm6.:fm7.:fm8.:fm9", :controller => "attaches/admin/#{sys}", :action => 'download'
    map.connect "_admin/attaches/#{sys}/:title_id/:name/:u_code/:d_code/:filename.:fm1.:fm2.:fm3.:fm4.:fm5.:fm6.:fm7.:fm8.:fm9.:fm10", :controller => "attaches/admin/#{sys}", :action => 'download'
  end

# --------------------------------------------------------------------------
## ツール
  map.connect '_tool/feeds/read',        :controller => 'cms/tool/feeds',       :action => 'read'
  map.connect '_tool/talks/*path',       :controller => 'cms/tool/talks',       :action => 'read'

# --------------------------------------------------------------------------
## 管理画面
  map.connect '_admin',                  :controller => 'intra/admin/front',    :action => 'index'
  map.connect '_admin/login.:format',    :controller => 'system/admin/account', :action => 'login'
  map.connect '_admin/login',            :controller => 'system/admin/account', :action => 'login'
  map.connect '_admin/logout.:format',   :controller => 'system/admin/account', :action => 'logout'
  map.connect '_admin/logout',           :controller => 'system/admin/account', :action => 'logout'
  map.connect '_admin/account.:format',  :controller => 'system/admin/account', :action => 'info'
  map.connect '_admin/account',          :controller => 'system/admin/account', :action => 'info'
  map.connect '_admin/reboot',           :controller => 'system/admin/reboot',  :action => 'index'
  map.connect '_public/system/account',        :controller => 'system/public/account', :action => 'login' if PUBLIC_LOGIN == 1
  map.connect '_public/system/account/login',  :controller => 'system/public/account', :action => 'login' if PUBLIC_LOGIN == 1
  map.connect '_public/system/logout',         :controller => 'system/public/account', :action => 'logout' if PUBLIC_LOGIN == 1

  map.connect '_admin/system/users/csvup'                 , :controller => 'system/admin/users'         , :action => 'csvup'
  map.connect '_admin/system/:parent/groups/csvup'        , :controller => 'system/admin/groups'        , :action => 'csvup'
  map.connect '_admin/system/:parent/groups/csvadd'       , :controller => 'system/admin/groups'        , :action => 'csvadd'
  map.connect '_admin/system/:parent/users_groups/csvup'  , :controller => 'system/admin/users_groups'  , :action => 'csvup'
  map.connect '_admin/system/:parent/group_histories/csvup'        , :controller => 'system/admin/group_histories'        , :action => 'csvup'
  map.connect '_admin/system/:parent/group_histories/csvadd'       , :controller => 'system/admin/group_histories'        , :action => 'csvadd'
  map.connect '_admin/system/:parent/users_group_histories/csvup'  , :controller => 'system/admin/users_group_histories'  , :action => 'csvup'
  map.connect '_admin/system/group_updates/csvup'                  , :controller => 'system/admin/group_updates'          , :action => 'csvup'

# --------------------------------------------------------------------------
## API
  #リマインダーチェッカー
  map.connect '_public/system/api/checker', :controller => 'system/public/api', :action => 'checker', :method => :post
  map.connect '_public/system/api/checker_login', :controller => 'system/public/api', :action => 'checker_login', :method => :get
  map.connect '_public/system/api/checker_login', :controller => 'system/public/api', :action => 'checker_login', :method => :post

# --------------------------------------------------------------------------
##携帯版SSO
  map.connect '_public/system/api/air_sso', :controller => 'system/public/api', :action => 'sso_login', :method => :get
  map.connect '_public/system/api/air_sso', :controller => 'system/public/api', :action => 'sso_login', :method => :post

# --------------------------------------------------------------------------
## INTRA
  mod = "intra"
  gw2 map, mod, :messages
  gw2 map, mod, :maintenances

# --------------------------------------------------------------------------
## SYSTEM
  mod = "system"
  gw2 map, mod, :admin_logs
  gw2 map, mod, :languages
  gw2 map, mod, :ldap_groups, :path_prefix=>"/:parent"
  gw2 map, mod, :ldap_users, :path_prefix=>"/:parent"
  gw2 map, mod, :ldap_temporaries
  gw2 map, mod, :users, :collection=>{ :csvup=>:post, :csvput=>:get }
  gwp2 map, mod,:users
  gw2 map, mod, :groups, :path_prefix=>"/:parent", :collection=>{ :csvup=>:post, :csvput=>:get, :csvadd=>:post }
  gw2 map, mod, :users_groups, :path_prefix=>"/:parent", :collection=>{ :csvup=>:post, :csvput=>:get }
  gw2 map, mod, :users_group_histories, :path_prefix=>"/:parent", :collection=>{ :csvup=>:post, :csvput=>:get }
  gw2 map, mod, :commitments
  gw2 map, mod, :contents
  gw2 map, mod, :roles
  gwp2 map, mod,:roles, :collection=>{ :user_fields=>:get}
  gwp2 map, mod,:role_names
  gwp2 map, mod,:role_name_privs, :collection=>{ :getajax=>:get }
  gwp2 map, mod,:priv_names
  gwp2 map, mod,:role_developers
  gw2 map, mod, :group_versions
  gw2 map, mod, :group_histories, :path_prefix=>"/:parent", :collection=>{ :csvup=>:post, :csvput=>:get, :csvadd=>:post }
#  gw2 map, mod, :group_history_rels
  gw2 map, mod, :idconversions
  gw2 map, mod, :group_change_ldaps
  gw2 map, mod, :group_changes , :collection=>{:prepare=>:get,:reflects=>:get,:pickup=>:get,:fixed=>:get,:csv=>:get,:deletes=>:get,:prepare_run=>:get,:reflects_run=>:get,:pickup_run=>:get,:fixed_run=>:get,:csv_run=>:get,:deletes_run=>:get}
  gw2 map, mod, :group_change_pickups
  gw2 map, mod, :group_updates , :collection=>{:csv=>:get,:csvup=>:post}
  gw2 map, mod, :group_nexts, :path_prefix=>"/:group_update"
  gw2 map, mod, :user_temporaries
  gw2 map, mod, :group_temporaries, :path_prefix=>"/:parent"
  gw2 map, mod, :users_group_temporaries, :path_prefix=>"/:parent"
#  gw2 map, mod, :group_history_temporaries, :path_prefix=>"/:parent"
  gw2 map, mod, :group_history_temporaries
  gw2 map, mod, :users_group_history_temporaries, :path_prefix=>"/:parent"
  gw2 map, mod, :custom_groups, :collection=>{:sort_update=>:put, :get_users=>:post,
    :create_all_group=>:get, :synchro_all_group=>:get, :user_add_sort_no=>:get }
  gwp2 map, mod, :custom_groups, :collection=>{:sort_update=>:put, :get_users=>:post,
    :create_all_group=>:get, :synchro_all_group=>:get, :user_add_sort_no=>:get }
  gw2 map, mod, :cache, :collection=>{:flush=>:get}


# --------------------------------------------------------------------------
## CMS
  mod = "cms"
  gw2 map, mod, :sites
  gw2 map, mod, :contents
  gw2 map, mod, :nodes, :path_prefix=>"/:parent"
  gw2 map, mod, :routes, :path_prefix=>"/:parent"
  gw2 map, mod, :maps, :path_prefix=>"/:parent"
  gw2 map, mod, :pages, :path_prefix=>"/:parent"
  gw2 map, mod, :edit_pages, :path_prefix=>"/:parent", :controller=>"pages/to_edit"
  gw2 map, mod, :recognize_pages, :path_prefix=>"/:parent", :controller=>"pages/to_recognize"
  gw2 map, mod, :publish_pages, :path_prefix=>"/:parent", :controller=>"pages/to_publish"
  gw2 map, mod, :texts
  gw2 map, mod, :layouts
  gw2 map, mod, :pieces
  gw2 map, mod, :piece_links, :path_prefix=>"/:piece", :controller=>"piece/links"
  gw2 map, mod, :tmp_files, :path_prefix=>"/:tmp"
  gw2 map, mod, :files, :path_prefix=>"/:parent"
  gw2 map, mod, :tool_tmp_files, :path_prefix=>"/:tmp", :controller=>"tool/tmp_files"
  map.connect '_admin/cms/:tmp/tmp_files/files/:name.:format' , :controller => 'cms/admin/tmp_files'  , :action => 'download'
  map.connect '_admin/cms/:parent/files/files/:name.:format'  , :controller => 'cms/admin/files'      , :action => 'download'
  map.connect '_admin/cms/tool/form/link_check' , :controller => 'cms/admin/tool/form/link_check' , :action => 'index'
  map.connect '_admin/cms/tool/form/uri_import' , :controller => 'cms/admin/tool/form/uri_import' , :action => 'index'
  map.connect '_admin/cms/tool/form/file_import', :controller => 'cms/admin/tool/form/file_import', :action => 'index'
  public.call map, mod, "nodes/:name.:format" , "nodes" , :action => 'index'
  public.call map, mod, "nodes/"              , "nodes" , :action => 'index'
  public.call map, mod, "maps/:name.:format"  , "maps"  , :action => 'index'
  public.call map, mod, "maps/"               , "maps"  , :action => 'index'

# --------------------------------------------------------------------------
## AD_MANAGER
  mod = "ad"
  gw2 map, mod, :banners, :path_prefix=>"/:content"

# --------------------------------------------------------------------------
## PREF
  mod = "pref"
  gw2 map, mod, :emergencies
  gw2 map, mod, :sections
  gw2 map, mod, :categories, :path_prefix=>"/:parent"
  gw2 map, mod, :attributes
  gw2 map, mod, :areas, :path_prefix=>"/:parent"
  gw2 map, mod, :docs, :path_prefix=>"/:content"
  gw2 map, mod, :edit_docs, :path_prefix=>"/:content", :controller=>'docs/to_edit'
  gw2 map, mod, :recognize_docs, :path_prefix=>"/:content", :controller=>'docs/to_recognize'
  gw2 map, mod, :publish_docs, :path_prefix=>"/:content", :controller=>'docs/to_publish'
  public.call map, mod, "sections/:name/index.:format"    , "sections"    , :action => 'show'
  public.call map, mod, "sections/:name"                  , "sections"    , :action => 'show'
  public.call map, mod, "sections/"                       , "sections"    , :action => 'index'
  public.call map, mod, "categories/:name/index.:format"  , "categories"  , :action => 'show'
  public.call map, mod, "categories/:name"                , "categories"  , :action => 'show'
  public.call map, mod, "categories/"                     , "categories"  , :action => 'index'
  public.call map, mod, "attributes/:name/index.:format"  , "attributes"  , :action => 'show'
  public.call map, mod, "attributes/:name"                , "attributes"  , :action => 'show'
  public.call map, mod, "attributes/"                     , "attributes"  , :action => 'index'
  public.call map, mod, "areas/:name/index.:format"       , "areas"       , :action => 'show'
  public.call map, mod, "areas/:name"                     , "areas"       , :action => 'show'
  public.call map, mod, "areas/"                          , "areas"       , :action => 'index'
  public.call map, mod, "docs/tab.js"                     , "doc/tabs"    , :action => 'index'
  public.call map, mod, "docs/:name/images/:file.:format" , "doc/images"  , :action => 'show'
  public.call map, mod, "docs/:name/files/:file.:format"  , "doc/files"   , :action => 'show'
  public.call map, mod, "docs/:name"                      , "docs"        , :action => 'show'
  public.call map, mod, "docs/index.:format"              , "docs"        , :action => 'index'
  public.call map, mod, "docs/"                           , "docs"        , :action => 'index'
  public.call map, mod, "recent_docs/index.:format"       , "recent_docs" , :action => 'index'
  public.call map, mod, "recent_docs/"                    , "recent_docs" , :action => 'index'
  public.call map, mod, "event_docs/:year/:month"         , "event_docs"  , :action => 'month'
  public.call map, mod, "tags/:name"                      , "tags"        , :action => 'index'

# --------------------------------------------------------------------------
## GW
  mod = "gw"
  map.connect '_admin/gw/test/dcn_feeds'                , :controller => 'gw/admin/test'                    , :action => 'dcn_feeds'
  map.connect '_admin/gw/test/convert_hash'             , :controller => 'gw/admin/test'                    , :action => 'convert_hash'
  map.connect '_admin/gw/test/import_csv'               , :controller => 'gw/admin/test'                    , :action => 'import_csv'
  map.connect '_admin/gw/test/download'                 , :controller => 'gw/admin/test'                    , :action => 'download'
  map.connect '_admin/gw/display_item_selects/csvup'    , :controller => 'gw/admin/display_item_selects'    , :action => 'csvup'
  map.connect '_admin/gw/year_fiscal_jps/csvup'         , :controller => 'gw/admin/year_fiscal_jps'         , :action => 'csvup'
  map.connect '_admin/gw/year_mark_jps/csvup'           , :controller => 'gw/admin/year_mark_jps'           , :action => 'csvup'
  map.connect '_public/gw/schedules/edit_ind_schedules' , :controller => 'gw/public/schedules'              , :action => 'edit_ind_schedules'
  map.connect '_public/gw/schedules/edit_ind_ssos'      , :controller => 'gw/public/schedules'              , :action => 'edit_ind_ssos'
  map.connect '_public/gw/schedules/edit_ind_mobiles'   , :controller => 'gw/public/schedules'              , :action => 'edit_ind_mobiles'
  map.connect '_public/gw/schedule_lists/import'    , :controller => 'gw/public/schedule_lists'         , :action => 'import'
  map.connect '_public/gw/pref_assembly_member_admins/csvup', :controller => 'gw/public/pref_assembly_member_admins', :action => 'csvup'
  map.connect '_public/gw/pref_executive_admins/csvup', :controller => 'gw/public/pref_executive_admins', :action => 'csvup'
  map.connect '_public/gw/pref_director_admins/csvup', :controller => 'gw/public/pref_director_admins', :action => 'csvup'
  public.call map, :gw, "ind_portal/:genre/:id/add", "ind_portal", :action => 'add'
  gw2 map, mod, :schedules, :collection=>{ :gadget=>:get }
  gw2 map, mod, :portal
  gw2 map, mod, :test, :collection=>{ :convert_hash=>:post, :import_csv=>:post, :download=>:post, :params_viewer=>:post ,:dcn_feeds=>:post},
    :member=>[:redirect_pref_soumu, :redirect_pref_cms, :redirect_pref_pieces ]
  gw2 map, mod, :link_sso, :collection=>{ :convert_hash=>:post, :import_csv=>:post, :download=>:post, :params_viewer=>:post },
    :member=>[:redirect_pref_soumu, :redirect_pref_cms, :redirect_pref_pieces, :redirect_to_dcn]
  gw2 map, mod, :zips, :member=>[ :get ]
  gw2 map, mod, :rssreader
  gwp2 map, mod, :schedules, :collection=>{ :show_month=>:get, :setting=>:get,
    :setting_system=>:get, :setting_holidays=>:get, :event_week=>:get, :event_month=>:get,
    :setting_ind=>:get, :setting_ind_schedules=>:get, :setting_ind_ssos=>:get, :setting_ind_mobiles=>:get, :setting_gw_link=>:get,
    :edit_ind_schedules=>:put, :edit_ind_ssos=>:put, :edit_ind_mobiles=>:put, :edit_gw_link=>:put,
    :editlending=>:put, :edit_1=>:put, :edit_2=>:put, :ical=>:get,
    :search=>:get }, :member=>[ :show_one, :editlending, :edit_1, :edit_2, :quote, :destroy_repeat ]
  gwp2 map, mod, :mobile_schedules,:collection=>{:list => :get, :mobile_manage => :post,:ind_list => :get}, :member=>[ :confirm, :delete, :delete_repeat ]
  gwp2 map, mod, :holidays
  gwp2 map, mod, :rssreader, :collection=>{ :edit_properties=>:get }
  gwp2 map, mod, :header
  gwp2 map, mod, :mobile_top_footer
  gwp2 map, mod, :mobile_footer
  gwp2 map, mod, :mobile_portal_function
  gwp2 map, mod, :mobile_common_header
  gwp2 map, mod, :tabs
  gwp2 map, mod, :tab_main
  gwp2 map, mod, :ind_portal, :collection=>{ :setting=>:get }, :member=>[ :up, :down, :add ]
  gwp2 map, mod, :todos, :member=>[ :finish, :quote, :confirm, :delete ]
  gwp2 map, mod, :schedule_todos, :collection=>{ :edit_user_property_schedule=>:get, :sample_create => :get, :shift_todo => :get },
    :member=>[ :finish, :quote ]
  gwp2 map, mod, :todo_settings, :collection=>{ :reminder=>:get, :edit_reminder=>:put,  :admin_deletes=>:get, :edit_admin_deletes=>:put, :schedule=>:get, :edit_schedule=>:put }
  gwp2 map, mod, :memos, :member=>[ :finish, :quote ,:confirm,:delete ] ,:collection=>{:list=>:post} #, :collection=>{ :setting=>:get }
  gwp2 map, mod, :mobile_participants, :collection => {:mobile_manage => :post}
  gwp2 map, mod, :memo_settings, :collection=>{ :reminder=>:get, :edit_reminder=>:put,  :admin_deletes=>:get, :edit_admin_deletes=>:put }
  gw2 map, mod, :icons, :path_prefix=>'/:igid'
  gw2 map, mod, :icon_groups
  gwp2 map, mod, :reminder
  gwp2 map, mod, :bbs_mock
  gwp2 map, mod, :address_folders
  gwp2 map, mod, :address_groups
  gwp2 map, mod, :address_users
  gw2 map, mod, :display_item_selects, :collection=>{ :csvup=>:post, :put_csv=>:get }
  gwp2 map, mod, :display_item_selects
  gw2 map, mod, :year_mark_jps, :collection=>{ :csvup=>:post, :csvput =>:get }
  gwp2 map, mod, :year_mark_jps
  gw2 map, mod, :year_fiscal_jps, :collection=>{ :csvup=>:post, :csvput =>:get }
  gwp2 map, mod, :prop_meetingrooms, :member=>[ :upload, :image_create, :image_destroy ]
  gwp2 map, mod, :prop_rentcars, :collection=>{ :mater_table_create=>:get }, :member=>[ :upload, :image_create, :image_destroy ]
  gwp2 map, mod, :prop_others, :member=>[ :upload, :image_create, :image_destroy ]
  gwp2 map, mod, :prop_extras, :collection=>{ :csvput=>:get, :confirm_all=>:get, :timeout_cancelled=>:get, :list=>:post, :results_delete_list=>:post }, :member=>[ :confirm, :rent, :return, :pm_create, :cancel ]
  gwp2 map, mod, :schedule_props, :collection=>{ :show_week=>:get,
    :show_month=>:get, :setting=>:get, :setting_system=>:get, :setting_ind=>:get,
    :getajax=>:get, :show_guard=>:get }, :member=>[ :show_one ]
  gwp2 map, mod, :schedule_users, :collection=>{ :getajax=>:get, :user_fields=>:get, :group_fields=>:get }, :only=>[]
  gwp2 map, mod, :schedule_events, :collection=>{ :select_approval_open=>:post, :csvput_week=>:get, :csvput_month=>:get },
    :member=>[ :approval, :open, :approval_cancel, :open_cancel ]
  gwp2 map, mod, :schedule_event_masters
  gwp2 map, mod, :section_admin_masters, :collection=>{ :select_clear=>:post, :clear=>:get }
  gwp2 map, mod, :section_admin_master_func_names
  gwp2 map, mod, :prop_extra_group_rentcar_masters
  gwp2 map, mod, :schedule_lists,
    :collection=>{ :user_fields => :get, :csvput=>:get, :icalput=>:get, :user_select=>:post, :user_add => :post, :user_delete => :post },
    :member=>{ :import=>:put }
  gwp2 map, mod, :prop_extra_pm_meetingrooms, :member=>[ :rent, :return, :show_group, :show_group_month, :delete_prop ], :collection=>{:summarize=>:get, :csvput=>:get}
  gwp2 map, mod, :prop_extra_pm_rentcars, :member=>[ :rent, :return, :show_group, :show_group_month, :delete_prop ], :collection=>{:summarize=>:get, :csvput=>:get, :show_month=>:get}
  gwp2 map, mod, :prop_extra_group_rentcars, :member=>[ :show_group, :show_group_month ]
  gwp2 map, mod, :schedule_settings, :collection=>{ :admin_deletes=>:get, :edit_admin_deletes=>:put, :export=>:get,:import=>:get,:import_file=>:post, }
  gwp2 map, mod, :schedule_help_configs
  # 一般施設　各課登録数 上限管理
  gwp2 map, mod, :prop_other_limits, :collection=>{ :synchro=>:get }
  # 管理者設定　メッセージ・年度・年号
  gwp2 map, mod, :admin_settings
  gwp2 map, mod, :admin_messages
  gwp2 map, mod, :prop_extra_pm_messages
  gwp2 map, mod, :year_fiscal_jps
  # タブ編集機能
  gwp2 map, mod, :edit_tabs, :collection=>{:list=>:get},:member=>{:updown=>:get}
  # ポータルリンクピース編集
  gwp2 map, mod, :edit_link_pieces, :collection=>{:list=>:get, :getajax_priv=>:get},:member=>{:updown=>:get,:swap=>:get}
  gwp2 map, mod, :edit_link_piece_csses, :collection=>{:list=>:get},:member=>[:updown , :renew]
  gwp2 map, mod, :ind_edit_link_pieces, :collection=>{:list=>:get,:fill_sso=>:get,:bookmark=>:get,:save_bookmark=>:post},:member=>{:swap=>:get}
  # RSSリーダー設定
  gwp2 map, mod, :rss_readers, :collection=>{ :edit_props=>:get, :save_props=>:post }, :member=>{ :swap=>:get }
  # メモ帳
  gwp2 map, mod, :notes, :collection=>{ :edit_props=>:get, :save_props=>:post, :fill_data=>:get }, :member=>{:move_higher=>:get, :move_lower=>:get}
  # ブログパーツ
  gwp2 map, mod, :blog_parts, :collection=>{ :edit_props=>:get, :save_props=>:post }, :member=>{ :swap=>:get }
  #広告管理
  gwp2 map, mod, :portal_adds, :member=>{:updown=>:get}
  gwp2 map, mod, :portal_bottom_adds
  gwp2 map, mod, :portal_left_adds
  #在庁表示
  gwp2 map, mod, :pref_assembly,:member=>{:state_change=>:get}
  gwp2 map, mod, :pref_assembly_member_admins,:member=>{:updown=>:get},:collection=>{:g_updown=>:get,:csvput =>:get,:csvup=>:post}
  gwp2 map, mod, :pref_executives,:member=>{:state_change=>:get}
  gwp2 map, mod, :pref_executive_admins,:member=>{:updown=>:get},:collection=>{:g_updown=>:get,:csvput =>:get,:csvup=>:post,:get_users =>:post,:sort_update=>:put}
  gw2 map, mod, :pref_directors # データ抽出ツール
  gwp2 map, mod, :pref_directors,:member=>{:state_change=>:get}
  gwp2 map, mod, :pref_director_admins,:member=>{:updown=>:get},:collection=>{:g_updown=>:get,:csvput =>:get,:csvup=>:post,:get_users =>:post,:sort_update=>:put}
  # 議員控え室　専用
  gwp2 map, mod, :pref_only_assembly,:member=>{:state_change=>:get}
  gwp2 map, mod, :pref_only_executives,:member=>{:state_change=>:get}
  gwp2 map, mod, :pref_only_directors,:member=>{:state_change=>:get}
  # コンテンツ設定
  gwp2 map, mod, :ind_portal_pieces, :collection=>{ :bookmark=>:get }, :member=>{ :swap=>:get }
  gwp2 map, mod, :ind_portal_settings, :collection=>{ :update=>:post }
  # 設定画面　集約（管理者・個人）
  gwp2 map, mod, :config_settings,:collection=>{:ind_settings=>:get}
  gwp2 map, mod, :countings,:collection=>{:memos=>:get, :mobiles=>:get}
  gwp2 map, mod, :mobile_settings,:collection=>{:access_edit=>:get,:access_updates=>:put,:password_edit=>:get,:password_updates=>:put}

########################################################################
# アンケート回答
  mod = "enquete"
  gwp2 map, mod, :menus
  public.call map, mod, "menus/:title_id/answers/:id/public_seal" , "menus/answers" , :action => 'public_seal'
  mod = "menus"
  gwp2 map, mod, :answers, :mod_prefix=>'enquete', :path_prefix=>"/:title_id"

# --------------------------------------------------------------------------
# アンケート設問作成管理
  mod = "questionnaire"
  gwp2 map, mod, :menus
  public.call map, mod, "menus/:id/closed" , "menus" , :action => 'closed'
  public.call map, mod, "menus/:id/open_enq" , "menus" , :action => 'open_enq'
  public.call map, mod, "menus/:parent_id/templates/:id/apply_template"   , "menus/templates"  , :action => 'apply_template'
  public.call map, mod, "menus/:parent_id/templates/new_base"             , "menus/templates"  , :action => 'new_base'
  public.call map, mod, "menus/:parent_id/templates/create_base"          , "menus/templates"  , :action => 'create_base'
  public.call map, mod, "menus/:parent_id/templates/:id/copy_form_fields" , "menus/templates"  , :action => 'copy_form_fields'
  gwp2 map, mod, :itemdeletes
  gwp2 map, mod, :templates, :member=>[:open, :close]
  mod = "menus"
  gwp2 map, mod, :form_fields, :mod_prefix=>'questionnaire', :path_prefix=>"/:parent_id"
  gwp2 map, mod, :templates, :mod_prefix=>'questionnaire', :path_prefix=>"/:parent_id"
  gwp2 map, mod, :previews, :mod_prefix=>'questionnaire', :path_prefix=>"/:parent_id"
  gwp2 map, mod, :answers, :mod_prefix=>'questionnaire', :path_prefix=>"/:parent_id"
  gwp2 map, mod, :csv_exports, :mod_prefix=>'questionnaire', :path_prefix=>"/:parent_id",:collection=>{:export_csv=>:put}
  gwp2 map, mod, :results, :mod_prefix=>'questionnaire', :path_prefix=>"/:parent_id",:collection=>{:answer_to_details=>:get, :result_close=>:get, :result_open=>:get}
  mod = "templates"
  gwp2 map, mod, :form_fields, :mod_prefix=>'questionnaire', :path_prefix=>"/:parent_id"
  gwp2 map, mod, :previews, :mod_prefix=>'questionnaire', :path_prefix=>"/:parent_id"

# --------------------------------------------------------------------------
# MONITOR
  mod = "gwmonitor"
  gw2  map, mod, :attachments,:path_prefix=>"/:parent_id"
  gw2  map, mod, :base_attachments,:path_prefix=>"/:parent_id"
  gw2  map, mod, :export_files,:path_prefix=>"/:title_id"
  gw2  map, mod, :ajaxgroups, :collection=>{ :getajax=>:get }, :only=>[]
  gw2  map, mod, :ajaxusergroups, :collection=>{ :getajax=>:get }, :only=>[]
  gwp2 map, mod, :menus
  gwp2 map, mod, :settings
  gwp2 map, mod, :help_configs
  gwp2 map, mod, :custom_groups, :collection=>{:sort_update=>:put }
  gwp2 map, mod, :custom_user_groups, :collection=>{:sort_update=>:put}
  gwp2 map, mod, :itemdeletes
  gwp2 map, mod, :builders
  public.call map, mod, "builders/:id/closed" , "builders" , :action => 'closed'
  public.call map, mod, "builders/:id/reopen" , "builders" , :action => 'reopen'
  public.call map, mod, "menus/:title_id/docs/:id/editing_state_setting" , "menus/docs" , :action => 'editing_state_setting'
  public.call map, mod, "menus/:title_id/docs/:id/draft_state_setting" , "menus/docs" , :action => 'draft_state_setting'
  public.call map, mod, "menus/:title_id/docs/:id/clone" , "menus/docs" , :action => 'clone'
  mod = "menus"
  gwp2 map, mod, :docs, :mod_prefix=>'gwmonitor', :path_prefix=>"/:title_id"
  gwp2 map, mod, :results, :mod_prefix=>'gwmonitor', :path_prefix=>"/:title_id"
  gwp2 map, mod, :csv_exports, :mod_prefix=>'gwmonitor', :path_prefix=>"/:title_id",:collection=>{:export_csv=>:put}
  gwp2 map, mod, :file_exports, :mod_prefix=>'gwmonitor', :path_prefix=>"/:title_id",:collection=>{:export_file=>:get}

# --------------------------------------------------------------------------
#　電子図書
  mod = "digitallibrary"

  public.call map, mod, "menus/" , "menus" , :action => 'index'

  public.call map, mod, "builders/" , "builders" , :action => 'index'
  public.call map, mod, "builders/create" , "builders" , :action => 'create'

  public.call map, mod, "cabinets/" , "cabinets" , :action => 'index'
  public.call map, mod, "cabinets/new" , "cabinets" , :action => 'new'
  public.call map, mod, "cabinets/create" , "cabinets" , :action => 'create'
  public.call map, mod, "cabinets/:id/delete" , "cabinets" , :action => 'destroy'
  public.call map, mod, "cabinets/:id/update" , "cabinets" , :action => 'update'
  public.call map, mod, "cabinets/:id/edit", "cabinets" , :action => 'edit'
  public.call map, mod, "cabinets/:id" , "cabinets" , :action => 'show'

  public.call map, mod, "docs/" , "docs" , :action => 'index'
  public.call map, mod, "docs/new" , "docs" , :action => 'new'
  public.call map, mod, "docs/:id/recognize_update" , "docs" , :action => 'recognize_update'
  public.call map, mod, "docs/:id/publish_update" , "docs" , :action => 'publish_update'
  public.call map, mod, "docs/create" , "docs" , :action => 'create'
  public.call map, mod, "docs/:id/delete" , "docs" , :action => 'destroy'
  public.call map, mod, "docs/:id/update" , "docs" , :action => 'update'
  public.call map, mod, "docs/:id/edit", "docs" , :action => 'edit'
  public.call map, mod, "docs/:id" , "docs" , :action => 'show'
  public.call map, mod, "docs/:parent_id/edit_file_memo/:id", "docs" , :action => 'edit_file_memo'

  #見出し
  public.call map, mod, "folders/" , "folders" , :action => 'index'
  public.call map, mod, "folders/new" , "folders" , :action => 'new'
  public.call map, mod, "folders/create" , "folders" , :action => 'create'
  public.call map, mod, "folders/:id/delete" , "folders" , :action => 'destroy'
  public.call map, mod, "folders/:id/update" , "folders" , :action => 'update'
  public.call map, mod, "folders/:id/edit", "folders" , :action => 'edit'
  public.call map, mod, "folders/:id" , "folders" , :action => 'show'

# --------------------------------------------------------------------------
# 書庫
  mod = "doclibrary"

  public.call map, mod, "menus/" , "menus" , :action => 'index'

  public.call map, mod, "cabinets/" , "cabinets" , :action => 'index'
  public.call map, mod, "cabinets/new" , "cabinets" , :action => 'new'
  public.call map, mod, "cabinets/create" , "cabinets" , :action => 'create'
  public.call map, mod, "cabinets/:id/delete" , "cabinets" , :action => 'destroy'
  public.call map, mod, "cabinets/:id/update" , "cabinets" , :action => 'update'
  public.call map, mod, "cabinets/:id/edit", "cabinets" , :action => 'edit'
  public.call map, mod, "cabinets/:id" , "cabinets" , :action => 'show'

  public.call map, mod, "categories/" , "categories" , :action => 'index'
  public.call map, mod, "categories/new" , "categories" , :action => 'new'
  public.call map, mod, "categories/create" , "categories" , :action => 'create'
  public.call map, mod, "categories/:id/delete" , "categories" , :action => 'destroy'
  public.call map, mod, "categories/:id/update" , "categories" , :action => 'update'
  public.call map, mod, "categories/:id/edit", "categories" , :action => 'edit'
  public.call map, mod, "categories/:id" , "categories" , :action => 'show'

  public.call map, mod, "folders/" , "folders" , :action => 'index'
  public.call map, mod, "folders/new" , "folders" , :action => 'new'
  public.call map, mod, "folders/create" , "folders" , :action => 'create'
  public.call map, mod, "folders/maintenance_acl" , "folders" , :action => 'maintenance_acl'
  public.call map, mod, "folders/:id/delete" , "folders" , :action => 'destroy'
  public.call map, mod, "folders/:id/update" , "folders" , :action => 'update'
  public.call map, mod, "folders/:id/edit", "folders" , :action => 'edit'
  public.call map, mod, "folders/:id" , "folders" , :action => 'show'

  public.call map, mod, "group_folders/" , "group_folders" , :action => 'index'
  public.call map, mod, "group_folders/new" , "group_folders" , :action => 'new'
  public.call map, mod, "group_folders/create" , "group_folders" , :action => 'create'
  public.call map, mod, "group_folders/sync_groups" , "group_folders" , :action => 'sync_groups'  #
  public.call map, mod, "group_folders/sync_children" , "group_folders" , :action => 'sync_children'  #
  public.call map, mod, "group_folders/:id/delete" , "group_folders" , :action => 'destroy'
  public.call map, mod, "group_folders/:id/update" , "group_folders" , :action => 'update'
  public.call map, mod, "group_folders/:id/edit", "group_folders" , :action => 'edit'
  public.call map, mod, "group_folders/:id" , "group_folders" , :action => 'show'

  public.call map, mod, "docs/" , "docs" , :action => 'index'
  public.call map, mod, "docs/new" , "docs" , :action => 'new'
  public.call map, mod, "docs/:id/recognize_update" , "docs" , :action => 'recognize_update'
  public.call map, mod, "docs/:id/publish_update" , "docs" , :action => 'publish_update'
  public.call map, mod, "docs/create" , "docs" , :action => 'create'
  public.call map, mod, "docs/:id/delete" , "docs" , :action => 'destroy'
  public.call map, mod, "docs/:id/update" , "docs" , :action => 'update'
  public.call map, mod, "docs/:id/edit", "docs" , :action => 'edit'
  public.call map, mod, "docs/:id" , "docs" , :action => 'show'
  public.call map, mod, "docs/:parent_id/edit_file_memo/:id", "docs" , :action => 'edit_file_memo'


# --------------------------------------------------------------------------
# 添付ファイルダウンロードリンク
  admin_attaches(map, 'gwqa')
  admin_attaches(map, 'gwbbs')
  admin_attaches(map, 'gwfaq')
  admin_attaches(map, 'doclibrary')
  admin_attaches(map, 'digitallibrary')
  admin_attaches(map, 'gwcircular')
  admin_attaches(map, 'gwmonitor')
  admin_attaches(map, 'gwmonitor_base')
  admin_attaches(map, 'sb11')

# --------------------------------------------------------------------------
# GWBOARD 共通
  mod = "gwboard"
  gw2 map, mod, :maps,:path_prefix=>"/:parent_id"
  gw2 map, mod, :images, :path_prefix=>"/:parent_id"
  gw2 map, mod, :attaches, :path_prefix=>"/:parent_id",:member=>{:update_file_memo=>:put}
  gw2 map, mod, :receipts, :member => [:show_object,:download_object]
  gw2 map, mod, :ajaxusers, :collection=>{ :getajax => :get ,:getajax_recognizer => :get }, :only=>[]
  gw2 map, mod, :ajaxgroups, :collection=>{ :getajax=>:get }, :only=>[]
  gw2 map, mod, :attachments,:path_prefix=>"/:parent_id",:member=>{:update_file_memo=>:put}

  public.call map, mod, "siteinfo/" , "siteinfo" , :action => 'index'
  public.call map, mod, "syntheses/" , "syntheses" , :action => 'index'
  public.call map, mod, "knowledges/" , "knowledges" , :action => 'index'
  public.call map, mod, "knowledge_makers/" , "knowledge_makers" , :action => 'index'

  public.call map, mod, "icons/" , "icons" , :action => 'index'
  public.call map, mod, "icons/new" , "icons" , :action => 'new'
  public.call map, mod, "icons/create" , "icons" , :action => 'create'
  public.call map, mod, "icons/:id/delete" , "icons" , :action => 'destroy'
  public.call map, mod, "icons/:id/update" , "icons" , :action => 'update'
  public.call map, mod, "icons/:id/edit", "icons" , :action => 'edit'
  public.call map, mod, "icons/:id" , "icons" , :action => 'show'

  public.call map, mod, "images/" , "images" , :action => 'index'
  public.call map, mod, "images/new" , "images" , :action => 'new'
  public.call map, mod, "images/create" , "images" , :action => 'create'
  public.call map, mod, "images/:id/delete" , "images" , :action => 'destroy'
  public.call map, mod, "images/:id/update" , "images" , :action => 'update'
  public.call map, mod, "images/:id/edit", "images" , :action => 'edit'
  public.call map, mod, "images/:id" , "images" , :action => 'show'

  gwp2 map, mod, :theme_registries
  gwp2 map, mod, :mutter_users
  gwp2 map, mod, :mutter_docs

# --------------------------------------------------------------------------
# 掲示板
  mod = "gwbbs"
  gwp2 map, mod, :theme_settings

  public.call map, mod, "menus/" , "menus" , :action => 'index'
  public.call map, mod, "itemdeletes/" , "itemdeletes" , :action => 'index'
  public.call map, mod, "itemdeletes/new" , "itemdeletes" , :action => 'new'
  public.call map, mod, "itemdeletes/create" , "itemdeletes" , :action => 'create'
  public.call map, mod, "itemdeletes/:id/delete", "itemdeletes" , :action => 'destroy'
  public.call map, mod, "itemdeletes/:mode/target_record", "itemdeletes" , :action => 'target_record'
  public.call map, mod, "itemdeletes/:mode/create_date_record", "itemdeletes" , :action => 'create_date_record'
  public.call map, mod, "itemdeletes/:mode/edit", "itemdeletes" , :action => 'edit'
  public.call map, mod, "itemdeletes/:mode" , "itemdeletes" , :action => 'show'

  public.call map, mod, "builders/" , "builders" , :action => 'index'
  public.call map, mod, "builders/create" , "builders" , :action => 'create'
  public.call map, mod, "builders/:id/gwbbs_output_files" , "builders" , :action => 'gwbbs_output_files'

  public.call map, mod, "synthesetup/" , "synthesetup" , :action => 'index'
  public.call map, mod, "synthesetup/new" , "synthesetup" , :action => 'new'
  public.call map, mod, "synthesetup/create" , "synthesetup" , :action => 'create'
  public.call map, mod, "synthesetup/:id/update" , "synthesetup" , :action => 'update'
  public.call map, mod, "synthesetup/:mode/edit" , "synthesetup" , :action => 'edit'

  public.call map, mod, "makers/" , "makers" , :action => 'index'
  public.call map, mod, "makers/new" , "makers" , :action => 'new'
  public.call map, mod, "makers/create" , "makers" , :action => 'create'
  public.call map, mod, "makers/:id/design_publish" , "makers" , :action => 'design_publish'
  public.call map, mod, "makers/:id/delete" , "makers" , :action => 'destroy'
  public.call map, mod, "makers/:id/update" , "makers" , :action => 'update'
  public.call map, mod, "makers/:id/edit", "makers" , :action => 'edit'
  public.call map, mod, "makers/:id" , "makers" , :action => 'show'

  public.call map, mod, "categories/" , "categories" , :action => 'index'
  public.call map, mod, "categories/new" , "categories" , :action => 'new'
  public.call map, mod, "categories/create" , "categories" , :action => 'create'
  public.call map, mod, "categories/:id/delete" , "categories" , :action => 'destroy'
  public.call map, mod, "categories/:id/update" , "categories" , :action => 'update'
  public.call map, mod, "categories/:id/edit", "categories" , :action => 'edit'
  public.call map, mod, "categories/:id" , "categories" , :action => 'show'

  public.call map, mod, "docs/" , "docs" , :action => 'index'
  public.call map, mod, "docs/new" , "docs" , :action => 'new'
  public.call map, mod, "docs/destroy_void_documents" , "docs" , :action => 'destroy_void_documents'
  public.call map, mod, "docs/:id/recognize_update" , "docs" , :action => 'recognize_update'
  public.call map, mod, "docs/:id/publish_update" , "docs" , :action => 'publish_update'
  public.call map, mod, "docs/:id/clone" , "docs" , :action => 'clone'
  public.call map, mod, "docs/:id/delete" , "docs" , :action => 'destroy'
  public.call map, mod, "docs/:id/update" , "docs" , :action => 'update'
  public.call map, mod, "docs/:id/edit", "docs" , :action => 'edit'
  public.call map, mod, "docs/:id" , "docs" , :action => 'show'
  public.call map, mod, "docs/:parent_id/edit_file_memo/:id", "docs" , :action => 'edit_file_memo'

  public.call map, mod, "comments/new" , "comments" , :action => 'new'
  public.call map, mod, "comments/create" , "comments" , :action => 'create'
  public.call map, mod, "comments/:id/delete" , "comments" , :action => 'destroy'
  public.call map, mod, "comments/:id/update" , "comments" , :action => 'update'
  public.call map, mod, "comments/:id/edit", "comments" , :action => 'edit'
  public.call map, mod, "comments/:id" , "comments" , :action => 'show'

  public.call map, mod, "csv_exports/:id" , "csv_exports" , :action => 'index'
  public.call map, mod, "csv_exports/:id/export_csv" , "csv_exports" , :action => 'export_csv'

# --------------------------------------------------------------------------
# 回覧板
  mod = "gwcircular"
  gw2  map, mod, :attachments,:path_prefix=>"/:parent_id"
  gw2  map, mod, :export_files,:path_prefix=>"/:parent_id"
  gw2  map, mod, :ajaxgroups, :collection=>{ :getajax=>:get }, :only=>[]

  gwp2 map, mod, :itemdeletes
  gwp2 map, mod, :basics
  gwp2 map, mod, :custom_groups, :collection=>{:sort_update=>:put}
  gwp2 map, mod, :settings
  gwp2 map, mod, :menus
  public.call map, mod, "menus/:id/circular_publish", "menus" , :action => 'circular_publish'
  gwp2 map, mod, :docs
  public.call map, mod, "docs/:id/already_update", "docs" , :action => 'already_update'
  mod = "menus"
  gwp2 map, mod, :commissions, :mod_prefix=>'gwcircular', :path_prefix=>"/:parent_id",:collection=>{:list=>:post}
  gwp2 map, mod, :csv_exports, :mod_prefix=>'gwcircular', :path_prefix=>"/:parent_id",:collection=>{:export_csv=>:put}
  gwp2 map, mod, :file_exports, :mod_prefix=>'gwcircular', :path_prefix=>"/:parent_id",:collection=>{:export_file=>:get}

# --------------------------------------------------------------------------
# GWFAQ
  mod = "gwfaq"
  public.call map, mod, "menus/" , "menus" , :action => 'index'

  public.call map, mod, "makers/" , "makers" , :action => 'index'
  public.call map, mod, "makers/new" , "makers" , :action => 'new'
  public.call map, mod, "makers/create" , "makers" , :action => 'create'
  public.call map, mod, "makers/:id/design_publish" , "makers" , :action => 'design_publish'
  public.call map, mod, "makers/:id/delete" , "makers" , :action => 'destroy'
  public.call map, mod, "makers/:id/update" , "makers" , :action => 'update'
  public.call map, mod, "makers/:id/edit", "makers" , :action => 'edit'
  public.call map, mod, "makers/:id" , "makers" , :action => 'show'

  public.call map, mod, "categories/" , "categories" , :action => 'index'
  public.call map, mod, "categories/new" , "categories" , :action => 'new'
  public.call map, mod, "categories/create" , "categories" , :action => 'create'
  public.call map, mod, "categories/:id/delete" , "categories" , :action => 'destroy'
  public.call map, mod, "categories/:id/update" , "categories" , :action => 'update'
  public.call map, mod, "categories/:id/edit", "categories" , :action => 'edit'
  public.call map, mod, "categories/:id" , "categories" , :action => 'show'

  public.call map, mod, "docs/" , "docs" , :action => 'index'
  public.call map, mod, "docs/new" , "docs" , :action => 'new'
  public.call map, mod, "docs/:id/recognize_update" , "docs" , :action => 'recognize_update'
  public.call map, mod, "docs/:id/publish_update" , "docs" , :action => 'publish_update'
  public.call map, mod, "docs/:id/delete" , "docs" , :action => 'destroy'
  public.call map, mod, "docs/:id/update" , "docs" , :action => 'update'
  public.call map, mod, "docs/:id/edit", "docs" , :action => 'edit'
  public.call map, mod, "docs/:id" , "docs" , :action => 'show'

# --------------------------------------------------------------------------
# GWQA
  mod = "gwqa"
  public.call map, mod, "menus/" , "menus" , :action => 'index'

  public.call map, mod, "makers/" , "makers" , :action => 'index'
  public.call map, mod, "makers/new" , "makers" , :action => 'new'
  public.call map, mod, "makers/create" , "makers" , :action => 'create'
  public.call map, mod, "makers/:id/design_publish" , "makers" , :action => 'design_publish'
  public.call map, mod, "makers/:id/delete" , "makers" , :action => 'destroy'
  public.call map, mod, "makers/:id/update" , "makers" , :action => 'update'
  public.call map, mod, "makers/:id/edit", "makers" , :action => 'edit'
  public.call map, mod, "makers/:id" , "makers" , :action => 'show'

  public.call map, mod, "docs/", "docs", :action => 'index'
  public.call map, mod, "docs/new" , "docs" , :action => 'new'
  public.call map, mod, "docs/create" , "docs" , :action => 'create'
  public.call map, mod, "docs/latest_answer" , "docs" , :action => 'latest_answer'
  public.call map, mod, "docs/:id/settlement" , "docs" , :action => 'settlement'
  public.call map, mod, "docs/:id/delete" , "docs" , :action => 'destroy'
  public.call map, mod, "docs/:id/update" , "docs" , :action => 'update'
  public.call map, mod, "docs/:id/edit", "docs", :action => 'edit'
  public.call map, mod, "docs/:id", "docs", :action => 'show'

  public.call map, mod, "categories/" , "categories" , :action => 'index'
  public.call map, mod, "categories/new" , "categories" , :action => 'new'
  public.call map, mod, "categories/create" , "categories" , :action => 'create'
  public.call map, mod, "categories/:id/delete" , "categories" , :action => 'destroy'
  public.call map, mod, "categories/:id/update" , "categories" , :action => 'update'
  public.call map, mod, "categories/:id/edit", "categories" , :action => 'edit'
  public.call map, mod, "categories/:id" , "categories" , :action => 'show'


# --------------------------------------------------------------------------
# Exception
  map.connect '404.:format',    :controller => 'default/exception', :action => 'index'
  map.connect '*path',          :controller => 'default/exception', :action => 'index'

#  # default
#  map.root :controller => 'system/admin/base'
#  map.connect ':controller/:action/:id'
#  map.connect ':controller/:action/:id.:format'
end
