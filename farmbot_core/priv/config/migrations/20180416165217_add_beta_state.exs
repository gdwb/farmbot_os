defmodule FarmbotCore.Config.Repo.Migrations.AddBetaState do
  use Ecto.Migration
  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("currently_on_beta", :bool, false)
  end
end
