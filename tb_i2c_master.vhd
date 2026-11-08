library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_i2c_master is
end tb_i2c_master;

architecture Behavioral of tb_i2c_master is

    component i2c_master
        Generic ( INPUT_CLK : INTEGER; BUS_CLK : INTEGER );
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
    signal addr      : STD_LOGIC_VECTOR(6 downto 0) := "1010000"; -- Адреса 0x50
    signal data_in   : STD_LOGIC_VECTOR(7 downto 0) := "00110101"; -- Дані 0x35
    signal busy      : STD_LOGIC;
    signal ack_error : STD_LOGIC;
    signal scl       : STD_LOGIC;
    signal sda       : STD_LOGIC := 'H'; -- Pull-up резистор

    constant CLK_PERIOD : time := 20 ns; -- 50 MHz

begin

    uut: i2c_master
        generic map ( INPUT_CLK => 50_000_000, BUS_CLK => 100_000 )
        port map (
            clk => clk, reset => reset, start => start,
            addr => addr, data_in => data_in,
            busy => busy, ack_error => ack_error,
            scl => scl, sda => sda
        );

    -- Генерація тактового сигналу CLK
    clk_process :process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Симуляція відповіді Slave (ACK)
    slave_ack_proc: process(scl)
    begin
        if falling_edge(scl) then
            sda <= '0'; 
        end if;
    end process;

    -- Стимули для перевірки
    stim_proc: process
    begin
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        start <= '1';
        wait for CLK_PERIOD * 10;
        start <= '0';

        wait for 2 ms;
        wait;
    end process;

end Behavioral;