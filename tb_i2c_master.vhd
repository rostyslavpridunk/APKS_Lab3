library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_i2c_master is
end tb_i2c_master;

architecture Behavioral of tb_i2c_master is

    component i2c_master
        Generic (
            INPUT_CLK : INTEGER := 50_000_000;
            BUS_CLK   : INTEGER := 100_000
        );
        Port (
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            start     : in  STD_LOGIC;
            addr      : in  STD_LOGIC_VECTOR(6 downto 0);
            data_in   : in  STD_LOGIC_VECTOR(7 downto 0);
            busy      : out STD_LOGIC;
            ack_error : out STD_LOGIC;
            scl       : out STD_LOGIC;
            sda       : inout STD_LOGIC
        );
    end component;

    signal clk       : STD_LOGIC := '0';
    signal reset     : STD_LOGIC := '0';
    signal start     : STD_LOGIC := '0';
    signal addr      : STD_LOGIC_VECTOR(6 downto 0) := "1010000"; -- 0x50
    signal data_in   : STD_LOGIC_VECTOR(7 downto 0) := "00110101"; -- 0x35
    signal busy      : STD_LOGIC;
    signal ack_error : STD_LOGIC;
    signal scl       : STD_LOGIC;
    signal sda       : STD_LOGIC := 'H'; -- Pull-up для I2C

    constant CLK_PERIOD : time := 20 ns; -- 50 МГц
    signal stop_sim     : boolean := false;

begin

    uut: i2c_master
        generic map (
            INPUT_CLK => 50_000_000,
            BUS_CLK   => 100_000
        )
        port map (
            clk       => clk,
            reset     => reset,
            start     => start,
            addr      => addr,
            data_in   => data_in,
            busy      => busy,
            ack_error => ack_error,
            scl       => scl,
            sda       => sda
        );

    -- Генератор тактового сигналу зі скінченним циклом
    clk_process :process
    begin
        while not stop_sim loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    -- Симуляція лінії SDA (Slave відправляє ACK)
    sda_process : process(scl)
    begin
        -- Симуляція відгуку від веденого пристрою
    end process;

    -- Процес подачі сигналів
    stim_proc: process
    begin
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- Старт передачі
        start <= '1';
        wait for 40 ns;
        start <= '0';

        -- Чекаємо завершення симуляції передачі I2C байта (~250 мкс)
        wait for 300 us;

        -- Завершуємо симуляцію
        stop_sim <= true;
        wait;
    end process;

end Behavioral;