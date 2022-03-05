require "rails_helper"

RSpec.describe API::MatchesController, type: :request do
  describe "POST /api/matches" do
    subject { post api_matches_path, params: params }

    let(:params) do
      {
        match: {
          match_players_attributes: [
            {
              team_id: "red",
              player_attributes: {
                name: "El Bicho"
              }
            },
            {
              team_id: "blue",
              player_attributes: {
                name: "Kerry"
              }
            }
          ]
        }
      }
    end

    it "creates a match object" do
      expect(Match.count).to eq(0)
      expect(Player.count).to eq(0)

      subject

      expect(response).to have_http_status(:created)
      expect(Match.count).to eq(1)
      expect(Match.last.match_players.count).to eq(2)
      expect(Player.count).to eq(2)
    end

    context "when a player already exists" do
      let!(:player) { create(:player, name: "El Bicho") }

      it "does not create a new player object for El Bicho" do
        expect(Match.count).to eq(0)
        expect(Player.count).to eq(1)

        subject

        expect(response).to have_http_status(:created)
        expect(Match.count).to eq(1)
        expect(Match.last.match_players.count).to eq(2)
        expect(Player.count).to eq(2)
        expect(Player.where(name: "El Bicho").count).to eq(1)
      end
    end
  end
end
