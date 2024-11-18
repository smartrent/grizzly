defmodule Grizzly.ZWave.CommandClasses.SensorMultilevel do
  @moduledoc """
  "SensorMultilevel" Command Class

  The Multilevel Sensor Command Class is used to advertise numerical sensor readings.
  """

  @behaviour Grizzly.ZWave.CommandClass

  alias Grizzly.ZWave.Encoding

  @impl Grizzly.ZWave.CommandClass
  def byte(), do: 0x31

  @impl Grizzly.ZWave.CommandClass
  def name(), do: :sensor_multilevel

  @sensor_types [
    # id, name, scales (in order by byte value)
    {0x01, :temperature, [:c, :f]},
    {0x02, :general, [:percentage, :dimensionless]},
    {0x03, :luminance, [:percentage, :lux]},
    {0x04, :power, [:watts, :btus_per_hour]},
    {0x05, :humidity, [:percentage, :absolute]},
    {0x06, :velocity, [:meters_per_second, :miles_per_hour]},
    {0x07, :direction, [:degrees]},
    {0x08, :atmospheric_pressure, [:kilopascals, :inches_of_mercury]},
    {0x09, :barometric_pressure, [:kilopascals, :inches_of_mercury]},
    {0x0A, :solar_radiation, [:watts_per_square_meter]},
    {0x0B, :dew_point, [:c, :f]},
    {0x0C, :rain_rate, [:millimeters_per_hour, :inches_per_hour]},
    {0x0D, :tide_level, [:meters, :feet]},
    {0x0E, :weight, [:kilograms, :pounds]},
    {0x0F, :voltage, [:volts, :millivolts]},
    {0x10, :current, [:amps, :milliamps]},
    {0x11, :co2_level, [:parts_per_million]},
    {0x12, :air_flow, [:cubic_meters_per_hour, :cubic_feet_per_minute]},
    {0x13, :tank_capacity, [:liters, :cubic_meters, :gallons]},
    {0x14, :distance, [:meters, :centimeters, :feet]},
    {0x15, :angle_position, [:percentage, :degrees]},
    {0x16, :rotation, [:revolutions_per_minute, :hertz]},
    {0x17, :water_temperature, [:c, :f]},
    {0x18, :soil_temperature, [:c, :f]},
    {0x19, :seismic_intensity, [:mercalli, :european_macroseismic, :liedu, :shindo]},
    {0x1A, :seismic_magnitude, [:local, :moment, :surface_wave, :body_wave]},
    {0x1B, :ultraviolet, [:uv_index]},
    {0x1C, :electrical_resistivity, [:ohm_meters]},
    {0x1D, :electrical_conductivity, [:siemens_per_meter]},
    {0x1E, :loudness, [:decibels, :a_weighted_decibels]},
    {0x1F, :moisture, [:percentage, :cubic_meters_per_cubic_meter, :kiloohms, :water_activity]},
    {0x20, :frequency, [:hertz, :kilohertz]},
    {0x21, :time, [:seconds]},
    {0x22, :target_temperature, [:c, :f]},
    {0x23, :particulate_matter_2_5, [:moles_per_cubic_meter, :micrograms_per_cubic_meter]},
    {0x24, :formaldehyde_level, [:moles_per_cubic_meter]},
    {0x25, :radon_concentration, [:becquerels_per_cubic_meter, :picocuries_per_liter]},
    {0x26, :methane_density, [:moles_per_cubic_meter]},
    {0x27, :voc_level, [:moles_per_cubic_meter, :parts_per_million]},
    {0x28, :co_level, [:moles_per_cubic_meter, :parts_per_million]},
    {0x29, :soil_humidity, [:percentage]},
    {0x2A, :soil_reactivity, [:ph]},
    {0x2B, :soil_salinity, [:moles_per_cubic_meter]},
    {0x2C, :heart_rate, [:beats_per_minute]},
    {0x2D, :blood_pressure, [:mm_hg_systolic, :mm_hg_diastolic]},
    {0x2E, :muscle_mass, [:kilograms]},
    {0x2F, :fat_mass, [:kilograms]},
    {0x30, :bone_mass, [:kilograms]},
    {0x31, :total_body_water, [:kilograms]},
    {0x32, :base_metabolic_rate, [:joules]},
    {0x33, :body_mass_index, [:index]},
    {0x34, :acceleration_x_axis, [:meters_per_square_second]},
    {0x35, :acceleration_y_axis, [:meters_per_square_second]},
    {0x36, :acceleration_z_axis, [:meters_per_square_second]},
    {0x37, :smoke_density, [:percentage]},
    {0x38, :water_flow, [:liters_per_hour]},
    {0x39, :water_pressure, [:kilopascals]},
    {0x3A, :rf_signal_strength, [:percentage, :decibel_milliwatts]},
    {0x3B, :particulate_matter_10, [:moles_per_cubic_meter, :micrograms_per_cubic_meter]},
    {0x3C, :respiratory_rate, [:breaths_per_minute]},
    {0x3D, :relative_modulation_level, [:percentage]},
    {0x3E, :boiler_water_temperature, [:c, :f]},
    {0x3F, :domestic_hot_water_temperature, [:c, :f]},
    {0x40, :outside_temperature, [:c, :f]},
    {0x41, :exhaust_temperature, [:c, :f]},
    {0x42, :water_chlorine_level, [:milligrams_per_liter]},
    {0x43, :water_acidity, [:ph]},
    {0x44, :water_oxidation_reduction_potential, [:millivolts]},
    {0x45, :heart_rate_lf_to_hf_ratio, [:unitless]},
    {0x46, :motion_direction, [:degrees]},
    {0x47, :applied_force, [:newtons]},
    {0x48, :return_air_temperature, [:c, :f]},
    {0x49, :supply_air_temperature, [:c, :f]},
    {0x4A, :condenser_coil_temperature, [:c, :f]},
    {0x4B, :evaporator_coil_temperature, [:c, :f]},
    {0x4C, :liquid_line_temperature, [:c, :f]},
    {0x4D, :discharge_line_temperature, [:c, :f]},
    {0x4E, :suction_pressure, [:kilopascals, :pounds_per_square_inch]},
    {0x4F, :discharge_pressure, [:kilopascals, :pounds_per_square_inch]},
    {0x50, :defrost_temperature, [:c, :f]},
    {0x51, :ozone, [:micrograms_per_cubic_meter]},
    {0x52, :sulfur_dioxide, [:micrograms_per_cubic_meter]},
    {0x53, :nitrogen_dioxide, [:micrograms_per_cubic_meter]},
    {0x54, :ammonia, [:micrograms_per_cubic_meter]},
    {0x55, :lead, [:micrograms_per_cubic_meter]},
    {0x56, :particulate_matter_1, [:micrograms_per_cubic_meter]},
    {0x57, :person_counter_entering, [:unitless]},
    {0x58, :person_counter_exiting, [:unitless]}
  ]

  @sensor_types_by_id Map.new(@sensor_types, &{elem(&1, 0), elem(&1, 1)})
  @sensor_types_by_name Map.new(@sensor_types, &{elem(&1, 1), elem(&1, 0)})
  @sensor_scales_by_type Map.new(@sensor_types, &{elem(&1, 1), elem(&1, 2)})

  @spec all_sensor_types() :: [atom()]
  def all_sensor_types(), do: Enum.map(@sensor_types, &elem(&1, 1))

  @spec sensor_type_scales(atom()) :: [atom()]
  def sensor_type_scales(sensor_type), do: Map.get(@sensor_scales_by_type, sensor_type)

  @spec encode_sensor_type(atom() | byte()) :: byte()
  def encode_sensor_type(sensor_type) when sensor_type in 0..255, do: sensor_type

  def encode_sensor_type(sensor_type) do
    Map.fetch!(@sensor_types_by_name, sensor_type)
  end

  @spec decode_sensor_type(byte()) :: {:ok, atom()} | :error
  def decode_sensor_type(byte) do
    Map.fetch(@sensor_types_by_id, byte)
  end

  @spec decode_sensor_types(binary) :: [atom()]
  def decode_sensor_types(binary) do
    binary
    |> Encoding.decode_bitmask()
    |> Enum.reduce([], fn v, acc ->
      case decode_sensor_type(v + 1) do
        {:ok, sensor_type} -> [sensor_type | acc]
        :error -> acc
      end
    end)
    |> Enum.reverse()
  end

  @spec encode_sensor_types([atom]) :: binary
  def encode_sensor_types(sensor_types) do
    sensor_types
    |> Enum.map(&(encode_sensor_type(&1) - 1))
    |> Encoding.encode_bitmask()
  end

  @spec encode_sensor_scale(atom(), atom() | byte()) :: byte() | nil
  def encode_sensor_scale(_, scale) when scale in 0..255, do: scale

  def encode_sensor_scale(sensor_type, scale) do
    byte =
      @sensor_scales_by_type
      |> Map.get(sensor_type, [])
      |> Enum.find_index(&(&1 == scale))

    if(byte in 0..255, do: byte, else: 0)
  end

  @spec decode_sensor_scale(atom(), byte()) :: atom()
  def decode_sensor_scale(sensor_type, index) do
    @sensor_scales_by_type
    |> Map.get(sensor_type, [])
    |> Enum.at(index, :unknown)
  end

  @spec encode_sensor_scales(atom(), [atom()]) :: <<_::8>>
  def encode_sensor_scales(sensor_type, scales) do
    scales
    |> Enum.map(&encode_sensor_scale(sensor_type, &1))
    |> Encoding.encode_bitmask()
  end

  @spec decode_sensor_scales(atom(), binary()) :: [atom()]
  def decode_sensor_scales(sensor_type, scales) do
    scales
    |> Encoding.decode_bitmask()
    |> Enum.map(&decode_sensor_scale(sensor_type, &1))
  end
end
