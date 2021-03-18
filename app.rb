require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'pg'
require 'sinatra/cookies'
require 'digest'
enable :sessions

client = PG::connect(
    :host => "localhost",
    :user => ENV.fetch("USER","teraonozomu"),:password =>'',
    :dbname => "test")

get '/' do
  # @p = ("select * from posts where #{session[:user]['id']}").to_s
  @users = client.exec_params("SELECT user_id,image from posts where user_id = #{session[:user]['id']}").to_a
  @users1 = client.exec_params("SELECT user_id,image from posts where user_id = 11").to_a
  @users2 = client.exec_params("SELECT user_id,image from posts where user_id = 14").to_a
    if session[:user].nil?
        redirect '/login'
    end
    return erb :top
end

########## usersテーブルに関連する処理 ##########
# 新規登録ページ
get '/register' do
    if session[:user] # ログイン済みだった場合
      session[:message] = { key: 'warning', value: 'すでにログインしています' } # フラッシュメッセージを代入
      return redirect '/mypage' # マイページへリダイレクトする。
    end
    @message = session.delete :message if session[:message] # session[:message]に値が代入されている場合、セッションメッセージ@messageへ代入し、session[:message]を削除する
    return erb :register
  end
  
  # 新規登録の処理
  post '/register' do
    name = params[:name]
    email = params[:email]
    password = params[:password]
    password_confirmation = params[:password_confirmation]
    title = params[:title]
    content = params[:content]


    # if params[:img] # 画像がある場合の処理
    #   tempfile = params[:img][:tempfile] # ファイルがアップロードされた場所
    #   save_to = "./public/images/#{params[:img][:filename]}" # ファイルを保存したい場所
    #   FileUtils.mv(save_to)
    #   post = client.exec_params("insert into posts(user_id, title_image) values($1, $2) returning *", [session[:user]["id"], params[:img][:filename]]).to_a.first
    #   end
    if name.empty? || email.empty? || password.empty? # 名前、メールアドレス、パスワードが空白だった場合
      session[:message] = { key: 'danger', value: '必須項目は入力してください' } # フラッシュメッセージを代入
      return redirect '/register' # 登録ページへリダイレクトする
    elsif password != password_confirmation # パスワードとパスワード確認用の値が一致しない場合
      session[:message] = { key: 'danger', value: 'パスワードが一致しません' } # フラッシュメッセージを代入
      return redirect '/register' # 登録ページへリダイレクトする
    elsif password.size < 6 # パスワードが6文字未満の場合
      session[:message] = { key: 'danger', value: 'パスワードは6文字以上入力してください' } # フラッシュメッセージを代入
      return redirect '/register' # 登録ページへリダイレクトする
    end
    begin # 例外処理。
      secure_password = params[:password_confirmation] # パスワードを暗号化し、secure_passwordに代入
      user = client.exec_params("insert into users(name, email, password) values($1, $2, $3) returning *", [name, email, secure_password]).to_a.first
    rescue PG::UniqueViolation # 例外処理。以下の処理を実行した際に、PG::UniqueViolationエラーが出た場合
      session[:message] = { key: 'danger', value: 'そのメールアドレスはすでに使われています' } # フラッシュメッセージを代入
      return redirect '/register' # 登録ページへリダイレクトする
    end
    session[:user] = user # ユーザー登録と同時にログインする
    session[:message] = { key: 'success', value: 'ログインしました' } # フラッシュメッセージを代入
    return redirect '/mypage' # マイページへリダイレクトする
  end


  

# get '/login' do
#     return erb :login
# end

# post '/login' do
#     email = params[:email]
#     password = params[:password]
#     user = client.exec_params("select * from users where email = $1 and password = $2", [email, password]).to_a.first
#     if user
#         session[:user] = user
#         return redirect '/'
#     end
#     return redirect '/login'
# end

# ログインの処理
# ログインページ
get '/login' do
    if session[:user] # ログイン済みの場合
      session[:message] = { key: 'warning', value: 'すでにログインしています' } # フラッシュメッセージを代入
      return redirect '/mypage' # マイページへリダイレクトする。
    end
    @message = session.delete :message if session[:message]  # session[:message]に値が代入されている場合、セッションメッセージ@messageへ代入し、session[:message]を削除する
    return erb :login
  end

post '/login' do
    email = params[:email]
    password = params[:password] # パスワードを暗号化し、passwordに代入
    user = client.exec_params("select * from users where email = $1 and password = $2",[email, password]).to_a.first
    if user
      session[:user] = user # session[:user]にuserを代入
      session[:message] = { key: 'success', value: 'ログインしました' } # フラッシュメッセージを代入
      return redirect '/mypage' # マイページへリダイレクトする
    end
    session[:message] = { key: 'danger', value: 'メールアドレスもしくはパスワードが違います' } # フラッシュメッセージを代入
    return redirect '/login'  # ログインページへリダイレクトする# ログインページへリダイレクトする
  end


delete '/logout' do
    session[:user] = nil
    redirect '/login'
end

get '/posts' do
    @posts = client.exec_params("select * from posts").to_a
    return erb :posts
end

get '/posts/new' do
    if session[:user].nil?
        redirect '/login'
    end
    return erb :new_posts
end


post '/posts' do
    if session[:user].nil?
        redirect '/login'
    end

    title = params[:title]
    content = params[:content]


    if params[:img] # 画像がある場合の処理
        tempfile = params[:img][:tempfile] # ファイルがアップロードされた場所
        save_to = "./public/images/#{params[:img][:filename]}" # ファイルを保存したい場所
        FileUtils.mv(tempfile, save_to)
        post = client.exec_params("insert into posts(user_id, title, content, image) values($1, $2, $3, $4) returning *", [session[:user]["id"], title, content, params[:img][:filename]]).to_a.first
      else # 画像がない場合の処理
        post = client.exec_params("insert into posts(user_id, title, content) values($1, $2, $3) returning *", [session[:user]["id"], title, content]).to_a.first
      end
      session[:message] = { key: 'success', value: '投稿しました' } # フラッシュメッセージを代入
      return redirect "/post/#{post['user_id']}"
end

get '/post/:id/edit' do
    @post = client.exec_params("select * from posts where id = $1", [params[:id]]).to_a.first
    return erb :edit_post
end

put '/post/:id/update' do
    title = params[:title]
    content = params[:content]


    if !params[:img].nil? # データがあれば処理を続行する
        tempfile = params[:img][:tempfile] # ファイルがアップロードされた場所
        save_to = "./public/images/#{params[:img][:filename]}"# ファイルを保存したい場所
        FileUtils.mv(tempfile, save_to)
        client.exec_params("update posts set title = $1, content = $2, image = $3 where id = $4", [title,content, params[:img][:filename],params[:id]])
    else
        client.exec_params("update posts set title = $1, content = $2 where id = $3", [title,content,params[:id]])
    end
    return redirect '/posts'
end

get '/index' do

    @posts = client.exec_params("select * from posts").to_a
    return erb :index
end

# 投稿詳細ページ
get '/post/:id' do
    # @posts = client.exec_params("SELECT * FROM posts WHERE user_id = 1").to_a
    @posts = client.exec_params("select * from posts where user_id = $1", [params[:id]])
    return erb :index
  end

post '/a' do
  redirect "/b/#{session[:user]['id']}"
end
get '/b/:user_id' do
    # @posts = client.exec_params("SELECT * FROM posts WHERE user_id = 1").to_a
    @posts = client.exec_params("select * from posts where user_id = $1", [params[:id]])
    return erb :index
  end

get '/mypage' do
  return redirect '/posts/new'
end