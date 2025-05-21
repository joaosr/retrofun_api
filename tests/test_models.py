import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from retrofun.models import Product
from sqlalchemy import select
from retrofun.import_products import save_products


@pytest.fixture()
def products(session):
    rows = [
        {
            "name": "Apple IIe",
            "manufacturer": "Apple Computer",
            "year": 1983,
            "cpu": "6502 CPU",
            "country": "USA",
        },
        {
            "name": "Atari 1200XL",
            "manufacturer": "Atari, Inc.",
            "year": 1983,
            "cpu": "6502",
            "country": "USA",
        },
        {
            "name": "Aquarius",
            "manufacturer": "Mattel",
            "year": 1983,
            "cpu": "Z80",
            "country": "USA",
        },
        {
            "name": "Atari 600XL",
            "manufacturer": "Atari, Inc.",
            "year": 1983,
            "cpu": "6502",
            "country": "USA",
        },
        {
            "name": "Atari 800XL",
            "manufacturer": "Atari, Inc.",
            "year": 1983,
            "cpu": "6502",
            "country": "USA",
        },
    ]

    save_products(session, rows)


@pytest.mark.asyncio
async def test_product_select_by_year(session: AsyncSession, products) -> None:
    q = (
        select(Product)
        .where(Product.year == 1983)
        .order_by(Product.name.asc())
        .limit(3)
    )
    expected = ["Apple IIe", "Aquarius", "Atari 1200XL"]
    result = await session.scalars(q)
    result = result.all()
    assert [item.name for item in result] == expected


@pytest.mark.asyncio
async def test_product_select_by_cpu(session: AsyncSession, products) -> None:
    q = select(Product.cpu).where(Product.cpu.like("%6502%"))
    expected = ["6502 CPU", "6502", "6502", "6502"]
    result = await session.scalars(q)
    result = result.all()
    assert result == expected
