
# Adapted from the official tt06-dffram-example 

import odb
import click
from reader import click_odb


@click.command()
@click.option(
    "--macro-x-pos",
    default=0,
    type=int,
    help="X position of the RAM32 macro in microns (tile/grid coordinate used by config).",
)
@click_odb
def power(reader, macro_x_pos: int):
    tech = reader.db.getTech()
    block = reader.block

    vpwr_net = block.findNet("VPWR")
    vgnd_net = block.findNet("VGND")
    if vpwr_net is None or vgnd_net is None:
        raise RuntimeError("Could not find VPWR/VGND in top-level block.")

    met4 = tech.findLayer("met4")
    if met4 is None:
        raise RuntimeError("Could not find met4 layer.")

    vpwr_wire = vpwr_net.getSWires()[0]
    vgnd_wire = vgnd_net.getSWires()[0]

    vpwr_bterm = vpwr_net.getBTerms()[0]
    vgnd_bterm = vgnd_net.getBTerms()[0]
    vpwr_bpin = vpwr_bterm.getBPins()[0]
    vgnd_bpin = vgnd_bterm.getBPins()[0]

    # Stripe geometry as the official DFFRAM example.
    # VPWR stripes
    for i in range(3):
        x = macro_x_pos * 1000 + 18280 + i * 153600
        odb.dbSBox_create(vpwr_wire, met4, x, 11880, x + 1600, 144120, "STRIPE")
        odb.dbBox_create(vpwr_bpin, met4, x, 11880, x + 1600, 144120)

    # VGND stripes
    for i in range(2):
        x = macro_x_pos * 1000 + 95080 + i * 153600
        odb.dbSBox_create(vgnd_wire, met4, x, 11880, x + 1600, 144120, "STRIPE")
        odb.dbBox_create(vgnd_bpin, met4, x, 11880, x + 1600, 144120)


if __name__ == "__main__":
    power()
