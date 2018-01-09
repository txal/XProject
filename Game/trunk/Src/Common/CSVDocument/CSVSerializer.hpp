#pragma once


namespace SG2DEX
{
	using namespace SG2D;
	using namespace SG2DFD;

	class CSVSerializer : public MemoryBlock<char, 4096>
	{
	public:
		void newRow()
		{
			if (offset > start && *(offset - 1) == ',')
				offset--;
			reserve(offset - start + 2);
			offset[0] = '\r';
			offset[1] = '\n';
			offset += 2;
		}
		void cat(int n)
		{
			reserve(offset - start + 16);
			offset += sprintf(offset, "%d,", n);
		}
		void cat(unsigned int u)
		{
			reserve(offset - start + 16);
			offset += sprintf(offset, "%u,", u);
		}
		void cat(float f)
		{
			reserve(offset - start + 32);
			offset += sprintf(offset, "%f,", f);
		}
		void cat(double d)
		{
			reserve(offset - start + 64);
			offset += sprintf(offset, "%lf,", d);
		}
		void cat(const String::TYPE* ptr, size_t len)
		{
			if (!ptr || !ptr[0])
			{
				reserve(offset - start + 1);
				offset[0] = ',';
				offset++;
			}
			else
			{
				const String::TYPE* end = ptr + len;
				reserve((offset - start) + (end - ptr) * 4);
				//内容中包含逗号，需要将内容整个以"CONTENT"包裹起来
				bool quote = strchr(ptr, ',') != NULL || strchr(ptr, '"') != NULL;
				if (quote)
				{
					offset[0] = '"';
					offset++;
				}
				//一个"转义为两个""
				while (ptr < end)
				{
					if (*ptr == '"')
					{
						offset[0] = '"';
						offset[1] = '"';
						offset += 2;
					}
					else 
					{
						offset[0] = *ptr;
						offset++;
					}
					ptr++;
				}
				if (quote)
				{
					offset[0] = '"';
					offset++;
				}
				offset[0] = ',';
				offset++;
			}
		}
		void cat(const String& s)
		{
			const String::TYPE *ptr = s.ptr();
			cat(ptr, s.length());
		}

		void cat(const Variant& var)
		{
			if (var.type == vBOOL)
			{
				cat(var.operator bool() ? "1" : "0");
			}
			//else if (var.type == vDOUBLE || var.type == vFLOAT)
			//{
			//	String s = N2S(var);
			//	cat(s.ptr(), s.length());
			//}
			else
			{
				String s = var;
				cat(s.ptr(), s.length());
			}
		}

		void saveToFile(const String& fileName)
		{
			//LocalFile file;
			//file.open(fileName, File::foCreate);
			//file.write(start, size());
			//file.close();
			FILE* file;
			file = fopen(fileName.ptr(), "a");
			fwrite(start, size(), 1, file);
			fclose(file);
		}
	};

}