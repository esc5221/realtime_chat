defmodule RealtimeChat.Chat.UserPosition do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "user_positions" do
    field :username, :string
    field :x, :integer
    field :y, :integer
    field :messages, {:array, :map}, default: []
    field :connected, :boolean, default: false
    field :current_message, :string
    field :user_id, :string
    field :last_active, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(user_position, attrs) do
    user_position
    |> cast(attrs, [:username, :x, :y, :messages, :connected, :current_message, :user_id, :last_active])
    |> validate_required([:username, :x, :y, :user_id])
  end

  def inactive_timeout, do: 24 * 60 * 60  # 1일

  def active?(user_position) do
    case user_position.last_active do
      nil -> false
      last_active ->
        diff = DateTime.diff(DateTime.utc_now(), last_active)
        diff < inactive_timeout()
    end
  end

  def get_opacity(user_position) do
    case user_position.last_active do
      nil -> 0.2
      last_active ->
        diff = DateTime.diff(DateTime.utc_now(), last_active)
        cond do
          diff < 5 * 60 -> 1.0        # 5분 이내: 100%
          diff < 30 * 60 -> 0.8       # 30분 이내: 80%
          diff < 3 * 60 * 60 -> 0.5   # 3시간 이내: 60%
          diff < inactive_timeout() -> 0.2  # 24시간 이내: 20%
          true -> 0.0
        end
    end
  end

  def update_last_active(user_position) do
    user_position
    |> changeset(%{last_active: DateTime.utc_now() |> DateTime.truncate(:second)})
  end

  def get_active_users(query \\ __MODULE__) do
    timeout = DateTime.utc_now() |> DateTime.add(-inactive_timeout(), :second)

    from u in query,
      where: u.connected == true and u.last_active > ^timeout
  end

  def find_optimal_position(existing_positions) do
    # 캔버스 크기 정의
    canvas_width = 1200
    canvas_height = 800
    min_distance = 150  # 최소 거리

    # 기존 위치가 없으면 중앙에 배치
    if Enum.empty?(existing_positions) do
      {div(canvas_width, 2), div(canvas_height, 2)}
    else
      # 그리드 포인트 생성 (50px 간격)
      grid_points = for x <- 50..canvas_width-50//50,
                       y <- 50..canvas_height-50//50,
                       do: {x, y}

      # 각 그리드 포인트에 대해 기존 위치들과의 최소 거리 계산
      grid_points
      |> Enum.map(fn point ->
        {point, calculate_min_distance(point, existing_positions)}
      end)
      |> Enum.filter(fn {_point, distance} -> distance >= min_distance end)
      |> Enum.max_by(fn {_point, distance} -> distance end)
      |> elem(0)
    end
  end

  defp calculate_min_distance({x, y}, existing_positions) do
    existing_positions
    |> Enum.map(fn %{x: ex, y: ey} ->
      dx = x - ex
      dy = y - ey
      :math.sqrt(dx * dx + dy * dy)
    end)
    |> Enum.min(fn -> :infinity end)
  end
end
