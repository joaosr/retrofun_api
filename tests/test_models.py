import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from retrofun.models import Product, Manufacturer, Country
from sqlalchemy import select, or_, func
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
            "name": "Hobbit",
            "manufacturer": "intercompex",
            "year": 1990,
            "cpu": "Z80 Compatible",
            "country": "USSR",
        },
        {
            "name": "Atari 600XL",
            "manufacturer": "Atari, Inc.",
            "year": 1986,
            "cpu": "6502",
            "country": "USA",
        },
        {
            "name": "Atari 800XL",
            "manufacturer": "Atari, Inc.",
            "year": 1986,
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


@pytest.mark.asyncio
async def test_product_select_by_cpu_year(session: AsyncSession, products) -> None:
    q = (
        select(Product.name, Product.cpu, Product.year)
        .where(
            or_(Product.cpu.like("%Z80%"), Product.cpu.like("%6502%")),
            Product.year < 1990,
        )
        .order_by(Product.name.asc())
    )
    expected = [
        ("Apple IIe", "6502 CPU", 1983),
        ("Aquarius", "Z80", 1983),
        ("Atari 1200XL", "6502", 1983),
        ("Atari 600XL", "6502", 1986),
        ("Atari 800XL", "6502", 1986),
    ]
    result = await session.execute(q)
    result = result.all()
    assert result == expected


@pytest.mark.asyncio
async def test_product_select_cpu_by_year_period(
    session: AsyncSession, products
) -> None:
    q = select(Product.cpu).where(Product.year.between(1980, 1989)).distinct()
    result = await session.scalars(q)
    result = result.all()
    expected = ["6502", "6502 CPU", "Z80"]
    assert result == expected


@pytest.mark.asyncio
async def test_manufacturer_select_by_name_initial_letter(
    session: AsyncSession, products
) -> None:
    q = (
        select(Manufacturer.name)
        .where(Manufacturer.name.like("A%"))
        .order_by(Manufacturer.name)
        .distinct()
    )
    result = await session.scalars(q)
    result = result.all()
    expected = ["Apple Computer", "Atari, Inc."]
    assert result == expected


@pytest.mark.asyncio
async def test_product_count_per_year(session: AsyncSession, products) -> None:
    counter = func.count(Product.id).label(None)
    q = select(Product.year, counter).group_by(Product.year).order_by(counter.desc())
    result = await session.execute(q)
    result = result.all()
    expected = [(1983, 3), (1986, 2), (1990, 1)]
    assert result == expected
