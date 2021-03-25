Function ConvertTo-UnifiedArray {
    <#
    .SYOPSIS
    Created this because i got sick of arrays inside arrays when it was not supose to have been
    .EXAMPLE
    $VaraibleName = ConvertTo-UnifiedArray $SomeArrayWithArrays
    .EXAMPLE
    $VaraibleName = $SomeArrayWithArrays |ConvertTo-UnifiedArray
    #>
    Param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        $Array,
        [switch]$JustReturn)
    Process {
        Foreach( $FirstObj in $Array) {
            if ( $FirstObj.Gettype().Name -match '\[\]|collect|array') {
                Foreach( $SecondObj in $FirstObj) {
                    if ( $SecondObj.Gettype().Name -match '\[\]|collect|array') {
                        $more = ConvertTo-UnifiedArray $SecondObj -JustReturn
                        Foreach( $ThirdObj in $more) {
                            $ThirdObj
                        }
                    }
                    else{
                        $SecondObj
                    }
                }
            }else{
                $FirstObj
            }
        }
    }
}