defmodule RealtimeChat.Chat.UserPosition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_positions" do
    field :username, :string
    field :x, :integer
    field :y, :integer
    field :messages, {:array, :map}, default: []
    field :connected, :boolean, default: true

    timestamps()
  end

  def changeset(user_position, attrs) do
    user_position
    |> cast(attrs, [:username, :x, :y, :messages, :connected])
    |> validate_required([:username, :x, :y])
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
