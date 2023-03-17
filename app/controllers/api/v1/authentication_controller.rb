class Api::V1::AuthenticationController < ApplicationController
  before_action :authorize_request, except: :login

  # POST /auth/login
  def login
    @user = User.find_by_email(params[:email])

    if @user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: @user.id)
      time = Time.now + 24.hours.to_i

      render json: {
        token: token,
        exp: time.strftime("%m-%d-%Y %H:%M"),
        user: @user,
      }, except: [:password_digest], status: :ok
    else
      render json: {
        error: "unauthorized",
      }, status: :unauthorized
    end
  end

  # GET /auth/me
  def me
    render json: @current_user, except: [:password_digest]
  end

  private

  def login_params
    params.permit(:email, :password)
  end
end
