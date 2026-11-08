library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_master is
    Generic (
        INPUT_CLK : INTEGER := 50_000_000; -- Вхідна частота 50 МГц
        BUS_CLK   : INTEGER := 100_000     -- Частота I2C SCL 100 кГц
    );
    Port (
        clk       : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        start     : in  STD_LOGIC;
        addr      : in  STD_LOGIC_VECTOR(6 downto 0);
        data_in   : in  STD_LOGIC_VECTOR(7 downto 0);
        busy      : out STD_LOGIC;
        ack_error : out STD_LOGIC;
        
        -- Лінії шини I2C
        scl       : out STD_LOGIC;
        sda       : inout STD_LOGIC
    );
end i2c_master;

architecture Behavioral of i2c_master is
    constant CLK_DIV : INTEGER := INPUT_CLK / (BUS_CLK * 4);
    
    -- Перейменовано ADDR на ADDR_STATE щоб уникнути конфлікту з портом addr
    type state_type is (IDLE, START_BIT, ADDR_STATE, ACK_ADDR, DATA_TX, ACK_DATA, STOP_BIT);
    signal state : state_type := IDLE;

    signal clk_cnt   : INTEGER range 0 to CLK_DIV := 0;
    signal data_clk  : STD_LOGIC := '0';
    signal bit_idx   : INTEGER range 0 to 7 := 7;
    signal tx_buffer : STD_LOGIC_VECTOR(7 downto 0);
    
    signal sda_out   : STD_LOGIC := '1';
    signal scl_out   : STD_LOGIC := '1';

begin

    -- Дільник тактової частоти
    process(clk, reset)
    begin
        if reset = '1' then
            clk_cnt <= 0;
            data_clk <= '0';
        elsif rising_edge(clk) then
            if clk_cnt = CLK_DIV - 1 then
                clk_cnt <= 0;
                data_clk <= not data_clk;
            else
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end process;

    -- Логіка FSM
    process(data_clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            busy <= '0';
            ack_error <= '0';
            sda_out <= '1';
            scl_out <= '1';
            bit_idx <= 7;
        elsif rising_edge(data_clk) then
            case state is
                when IDLE =>
                    busy <= '0';
                    sda_out <= '1';
                    scl_out <= '1';
                    if start = '1' then
                        state <= START_BIT;
                        tx_buffer <= addr & '0'; -- Режим запису ('0')
                        busy <= '1';
                        ack_error <= '0';
                    end if;

                when START_BIT =>
                    sda_out <= '0';
                    scl_out <= '1';
                    state <= ADDR_STATE;
                    bit_idx <= 7;

                when ADDR_STATE =>
                    scl_out <= '0';
                    sda_out <= tx_buffer(bit_idx);
                    if bit_idx = 0 then
                        state <= ACK_ADDR;
                    else
                        bit_idx <= bit_idx - 1;
                    end if;

                when ACK_ADDR =>
                    scl_out <= '1';
                    sda_out <= 'Z'; -- Звільняємо SDA для ACK від Slave
                    if sda = '0' then
                        tx_buffer <= data_in;
                        bit_idx <= 7;
                        state <= DATA_TX;
                    else
                        ack_error <= '1';
                        state <= STOP_BIT;
                    end if;

                when DATA_TX =>
                    scl_out <= '0';
                    sda_out <= tx_buffer(bit_idx);
                    if bit_idx = 0 then
                        state <= ACK_DATA;
                    else
                        bit_idx <= bit_idx - 1;
                    end if;

                when ACK_DATA =>
                    scl_out <= '1';
                    sda_out <= 'Z';
                    if sda /= '0' then
                        ack_error <= '1';
                    end if;
                    state <= STOP_BIT;

                when STOP_BIT =>
                    scl_out <= '1';
                    sda_out <= '1';
                    state <= IDLE;
            end case;
        end if;
    end process;

    scl <= scl_out;
    sda <= sda_out when sda_out = '0' else 'Z';

end Behavioral;