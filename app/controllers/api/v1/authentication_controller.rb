module Api
  module V1
    # Handles API authentication
    class AuthenticationController < ApplicationController
      before_action :authorize_request, except: :login
      before_action :set_user, :set_time, only: :login

      def login
        if @user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: @user.id)

          render json: {
            token:,
            exp: @time.strftime('%m-%d-%Y %H:%M'),
            user: @user
          }, except: :password_digest, status: :ok
        else
          render json: {
            error: 'unauthorized'
          }, status: :unauthorized
        end
      end

      def me
        render json: @current_user, except: :password_digest
      end

      private

      def set_user
        @user = User.find_by_email(params[:email])
      end

      def set_time
        @time = Time.now + 24.hours.to_i
      end

      def login_params
        params.permit(:email, :password)
      end
    end
  end
end
