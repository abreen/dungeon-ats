#define DEFAULT_UNIVERSE_PATH "default.universe"

fun open_universe (path: string): void =
  let
    val file: FILEref = fileref_open_exn(path, file_mode_r)
    fun read_space (): void =
      let
        val id = strptr2string(fileref_get_line_string(file))

        val north_exit = strptr2string(fileref_get_line_string(file))
        val east_exit = strptr2string(fileref_get_line_string(file))
        val south_exit = strptr2string(fileref_get_line_string(file))
        val west_exit = strptr2string(fileref_get_line_string(file))

        val name = strptr2string(fileref_get_line_string(file))
        val desc = strptr2string(fileref_get_line_string(file))

        val room = create_room(id, name, desc)
      in
        if eq_string_string(id, "") then ()
        else begin
          (
            case north_exit of
            | "~" => ()
            | exit_id => set_exit_id(room, exit_id, North)
          );
          (
            case east_exit of
            | "~" => ()
            | exit_id => set_exit_id(room, exit_id, East)
          );
          (
            case south_exit of
            | "~" => ()
            | exit_id => set_exit_id(room, exit_id, South)
          );
          (
            case west_exit of
            | "~" => ()
            | exit_id => set_exit_id(room, exit_id, West)
          );
          if fileref_isnot_eof(file) then
            read_space()      // read another one
          else ()
        end
      end

  in (read_space(); fileref_close(file))
  end
