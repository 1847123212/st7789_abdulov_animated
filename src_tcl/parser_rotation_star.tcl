proc bmp_parsing {file_name} {

    set file_id [open $file_name r+]
    set bmp_data_offt -1

    fconfigure $file_id -translation binary

    binary scan [read $file_id] "H4" bmp_hdr_byte

    #compatible format for fucking BMP header
    if {$bmp_hdr_byte!="424d"} {
        # puts "Error, there is not BMP file"
        return -1
    } else {
        # puts "-=BMP_PARSING=- :: BitMap image format"
    }

    seek $file_id 2

#        binary scan [read $file_id 8] "H8" bmp_size_of_file
#       x - from hexadecimal 
#       0 - from 0 byte of current offset 
#       i - reversed fomat (I - direct format)
#       read file id 4 - 4 bytes from file
#       s - to signed  

    binary scan [read $file_id 4] "x0i*" bmp_size_of_file

    # puts "-=BMP_PARSING=- :: [$bmp_size_of_file] bytes"

    seek $file_id 10

    binary scan [read $file_id 4] "x0i*" bmp_data_offt

    # puts "-=BMP_PARSING=- :: BITMAP data block start address [$bmp_data_offt] bytes"

    seek $file_id 14
    binary scan [read $file_id 4] "x0i*" dib_header
    # puts "-=BMP_PARSING=- :: DIB header size: [$dib_header] bytes"
    
    seek $file_id 18 
    binary scan [read $file_id 4] "x0i*" width_of_bitmap
    if {$width_of_bitmap<0} {
        set width_of_bitmap [expr {0 - [$width_of_bitmap]}]
    }
    # puts "BMP_PARSING width_of_bitmap: [$width_of_bitmap] pixels"

    seek $file_id 22
    binary scan [read $file_id 4] "x0i*" height_of_bitmap
    if {$height_of_bitmap<0} {
        set height_of_bitmap [expr {0-$height_of_bitmap}]
    }


    if {($height_of_bitmap==240)&&($width_of_bitmap==240)} {
        # puts "-=BMP_PARSING=- :: correct resolution of picture $height_of_bitmap x $width_of_bitmap"
    } else {
        # puts "-=BMP_PARSING=- :: incorrect resolution of picture $height_of_bitmap x $width_of_bitmap"
        return -1
    }

    close $file_id

    return $bmp_data_offt;

}


set string_length_limit 240 
set string_length_index 0 

set line_limit 240 
set line_index 0 

set current_color 0 
set current_value 0

set string_index 0 

set start_file_grad 0 
set delta_file_grad 5 
set grad_steps 9 

set file_iter 0 

set filename_part_source gr.bmp 
set filename_part_dest gr.memory 

for {set $file_iter $start_file_grad} {$file_iter < $grad_steps} {incr file_iter} {

    set output_string "" 

    set start_address 0 

    set file_name [expr {$file_iter * $delta_file_grad}]
    set file_name_source c:/BiboranExperience/st7789_layer_animation/resources/$file_name$filename_part_source
    set file_name_destinate c:/BiboranExperience/st7789_layer_animation/resources/$file_name$filename_part_dest

    puts "-=MAIN=- :: parsing file $file_name_source ..." 

    set start_address [bmp_parsing $file_name_source]
    if {$start_address==-1} {
        puts "-=MAIN=- :: Error with start address"
        return
    } else {
        puts "-=MAIN=- :: start address of data segment is $start_address bytes"
    }

    set file_id [open $file_name_source r+]

    fconfigure $file_id -translation binary 

    for {set line_index 0} {$line_index < $line_limit} {incr line_index} {
        set output_string $output_string

        for {set string_length_index 0 } {$string_length_index < $string_length_limit} {incr string_length_index} {

            seek $file_id [expr {$start_address + ((($line_index * $string_length_limit) + $string_length_index)*2) }]

            binary scan [read $file_id] "H4" current_value

            if {$current_value=="ffff"} {
                set current_color "0 "
            } elseif {$current_value=="0000"} {
                set current_color "1 "
            } elseif {$current_value!="0000"||$current_value!="ffff"} {
                set current_color "z "
            }
            set output_string $output_string$current_color
        }
    }
    set fo [open $file_name_destinate w] 
    puts $fo $output_string
    close $fo
    close $file_id
}




set output_string "" 
set start_address 0 
set line_index 0 
set string_length_index 0 

set line_limit 240 
set string_length_limit 240 

set start_file_grad 0 
set delta_file_grad 5 
set grad_steps 9 
set file_iter 0 

set file_name [expr {$file_iter * $delta_file_grad}]
set filename_part_dest_total gr.memory_total


set file_data [list ]

set file_name_destinate_total C:/BiboranExperience/st7789_layer_animation/resources/$file_name$filename_part_dest_total
puts $file_name_destinate_total

set indexator 0 

puts "time : y:x"

for {set line_index 0} {$line_index < $line_limit} {incr line_index} {

    for {set string_length_index 0 } {$string_length_index < $string_length_limit} {incr string_length_index} {

        for {set $file_iter $start_file_grad} {$file_iter < $grad_steps} {incr file_iter} {
            set file_name [expr {$file_iter * $delta_file_grad}]
            set file_name_source C:/BiboranExperience/st7789_layer_animation/resources/$file_name$filename_part_dest
            set fp [open $file_name_source r] 
            set file_data [read $fp] 
            set output_string $output_string[lindex $file_data $indexator] 
            close $fp 
        }

        set indexator [expr {$indexator+1}]

        set output_string "$output_string "
        set file_iter 0 
    }
    set string_length_index 0 

    set system_time [clock seconds]
    puts "[clock format $system_time -format %H:%M:%S] :: [$line_index][$string_length_index]"
}


set fo_combine [open $file_name_destinate_total w]
puts $fo_combine $output_string 
close $fo_combine
