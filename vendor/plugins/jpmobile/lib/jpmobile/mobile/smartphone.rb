module Jpmobile
  module Mobile
    class Smartphone < AbstractMobile
      # 対応するuser-agentの正規表現
      USER_AGENT_REGEXP = /iPhone|iPad|Opera Mini|Android.*Mobile|Windows Phone/

      # cookieに対応しているか？
      def supports_cookie?
        true
      end
      def Smartphone?
       true
      end
    end
  end
end