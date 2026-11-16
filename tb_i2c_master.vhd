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
    signal sda       : STD_LOGIC := 'H'; -- Pull-up резистор для шини I2C

    constant CLK_PERIOD : time := 20 ns; -- 50 МГц
    signal stop_sim     : boolean := false;

begin

    -- Підключення тестованого модуля (UUT)
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
    clk_process : process
    begin
        while not stop_sim loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    -- Симуляція лінії SDA (Slave відправляє ACK на 9-му та 18-му тактах)
    sda_process : process(scl)
        variable edge_cnt : integer := 0;
    begin
        if falling_edge(scl) then
            if busy = '1' then
                edge_cnt := edge_cnt + 1;
                -- Після 8 біт адреси (9-й такт) та 8 біт даних (18-й такт) Slave тягне SDA в '0'
                if edge_cnt = 9 or edge_cnt = 18 then
                    sda <= '0';
                else
                    sda <= 'H';
                end if;
            else
                edge_cnt := 0;
                sda <= 'H';
            end if;
        end if;
    end process;

    -- Процес подачі тестових сигналів
    stim_proc : process
    begin
        -- Початкове скидання
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- Старт передачі
        start <= '1';
        wait for 10 us; -- Тримаємо start достатньо довго, щоб data_clk точно його зловив
        start <= '0';

        -- Чекаємо завершення повної передачі адреси + даних (~220 мкс)
        wait for 250 us;

        -- Завершуємо симуляцію
        stop_sim <= true;
        wait;
    end process;

end Behavioral;