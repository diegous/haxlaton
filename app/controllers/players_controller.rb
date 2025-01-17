class PlayersController < ApplicationController
  def index
    @players = Player.all
      .includes(match_players: [:match, :player_stat])
      .where(match_players: { created_at: from_date..to_date })
      .order("match_players.created_at": :desc)

    @players_table = @players.map do |player|
      total_games = player.match_players.size
      total_wins = player.match_players.select { |mp| mp.match.winner_team_id == mp.team_id }.size
      total_losses = total_games - total_wins
      victory_rate = (total_wins.to_f / total_games.to_f * 100).round(2)
      player_stats = player.match_players.map(&:player_stat).compact
      total_goals = player_stats.map(&:goals).sum
      total_assists = player_stats.map(&:assists).sum
      total_own_goals = player_stats.map(&:own_goals).sum

      {
        "ID" => player.id,
        "Name" => player.name,
        "Last played at" =>  player.match_players.last&.created_at,
        "Elo" =>  player.elo,
        "Victory rate" =>  victory_rate,
        "Total games" =>  total_games,
        "Total wins" =>  total_wins,
        "Total losses" =>  total_losses,
        "Total goals" =>  total_goals,
        "Total assists" =>  total_assists,
        "Total own goals" =>  total_own_goals,
      }
    end
  end

  ###
  #
  # Chart data endpoints
  # These are used by chartkick to generate charts asynchronously
  #
  ###
  def elos_by_date
    players = Player.all.includes(:elo_changes).where(elo_changes: { created_at: from_date.beginning_of_day..to_date.end_of_day })

    data = players.map do |player|
      # Fetch latest elo for a player on a given date
      last_elos_by_date = player.elo_changes.group_by { |ec| ec.created_at.to_date }.map do |date, elos|
        [date, elos.sort_by(&:created_at).last.current_elo]
      end.to_h

      # Fill missing dates with the previous elo the player had. Empty if no elo changes.
      # This is to prevent the chart from showing a gap between the first and the next date a player had a match.
      (from_date..to_date).each do |date|
        last_elos_by_date[date] ||= last_elos_by_date[date - 1.day]
      end

      {
        name: player.name,
        data: last_elos_by_date
      }
    end

    render json: data
  end

  def from_date
    @from_date ||= Date.parse(params[:from_date] || 3.months.ago.to_s)
  end
  helper_method :from_date

  def to_date
    @to_date ||= Date.parse(params[:to_date] || Date.today.to_s)
  end
  helper_method :to_date
end
